const crypto = require('crypto');
const Commande = require('../models/Commande');

const PAWAPAY_BASE_URL =
  process.env.PAWAPAY_BASE_URL ||
  ((process.env.PAWAPAY_ENV || 'sandbox').toLowerCase() === 'production'
    ? 'https://api.pawapay.io'
    : 'https://api.sandbox.pawapay.io');

function normalizePhoneNumber(rawPhone) {
  const cleaned = String(rawPhone || '').replace(/[^\d+]/g, '');
  if (!cleaned) return null;

  const hasPlus = cleaned.startsWith('+');
  let digits = cleaned.replace(/\D/g, '');
  const countryCode = String(process.env.PAWAPAY_PHONE_COUNTRY_CODE || '').replace(/\D/g, '');

  if (!hasPlus && countryCode && !digits.startsWith(countryCode)) {
    if (digits.startsWith('0')) {
      digits = digits.slice(1);
    }
    digits = `${countryCode}${digits}`;
  }

  return digits || null;
}

function buildCustomerMessage(referenceValue) {
  const sanitizedRef = String(referenceValue || '')
    .replace(/[^a-zA-Z0-9]/g, '')
    .slice(-8);
  const message = `Kala ${sanitizedRef || 'Pay'}`.slice(0, 22);
  return message.length >= 4 ? message : 'Kala Pay';
}

function isValidAbsoluteUrl(value) {
  if (!value) return false;
  try {
    const parsed = new URL(value);
    return parsed.protocol === 'http:' || parsed.protocol === 'https:';
  } catch (_error) {
    return false;
  }
}

function isLocalOrPrivateHost(hostname) {
  const host = String(hostname || '').toLowerCase();
  if (!host) return true;
  if (host === 'localhost' || host === '127.0.0.1' || host === '0.0.0.0' || host === '::1') {
    return true;
  }

  if (/^\d+\.\d+\.\d+\.\d+$/.test(host)) {
    const [a, b] = host.split('.').map((n) => Number(n));
    if (a === 10) return true;
    if (a === 127) return true;
    if (a === 192 && b === 168) return true;
    if (a === 172 && b >= 16 && b <= 31) return true;
  }

  return false;
}

function isValidPawapayReturnUrl(value) {
  if (!isValidAbsoluteUrl(value)) return false;
  try {
    const parsed = new URL(value);
    if (parsed.protocol !== 'https:') return false;
    if (isLocalOrPrivateHost(parsed.hostname)) return false;
    return true;
  } catch (_error) {
    return false;
  }
}

function resolveProvider(modePaiement) {
  const byMode = {
    wave: process.env.PAWAPAY_PROVIDER_WAVE,
    orange_money: process.env.PAWAPAY_PROVIDER_OM,
  };

  const explicitProvider = byMode[modePaiement] || process.env.PAWAPAY_PROVIDER;
  if (explicitProvider) {
    return explicitProvider;
  }

  const country = (process.env.PAWAPAY_COUNTRY || 'SEN').toUpperCase();
  const defaultsByCountry = {
    wave: {
      SEN: 'WAVE_SEN',
      CIV: 'WAVE_CIV',
    },
    orange_money: {
      SEN: 'ORANGE_SEN',
      CIV: 'ORANGE_CIV',
      CMR: 'ORANGE_CMR',
      BFA: 'ORANGE_BFA',
      SLE: 'ORANGE_SLE',
    },
  };

  return defaultsByCountry[modePaiement]?.[country] || null;
}

async function callPawapay(endpoint, payload) {
  const apiKey = process.env.PAWAPAY_API_KEY;
  if (!apiKey) {
    throw new Error('PAWAPAY_API_KEY manquant dans les variables d environnement');
  }

  if (typeof fetch !== 'function') {
    throw new Error('fetch indisponible dans cette version de Node.js');
  }

  const response = await fetch(`${PAWAPAY_BASE_URL}${endpoint}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  let responseBody = null;
  try {
    responseBody = await response.json();
  } catch (_error) {
    responseBody = null;
  }

  if (!response.ok) {
    const details =
      responseBody?.message ||
      responseBody?.error ||
      responseBody?.details ||
      JSON.stringify(responseBody || {});

    throw new Error(`Echec pawaPay (${response.status}): ${details}`);
  }

  return responseBody;
}

function resolvePaymentPageReturnUrl(req, explicitReturnUrl) {
  if (isValidPawapayReturnUrl(explicitReturnUrl)) {
    return explicitReturnUrl;
  }

  if (isValidPawapayReturnUrl(process.env.PAWAPAY_RETURN_URL)) {
    return process.env.PAWAPAY_RETURN_URL;
  }

  if (isValidPawapayReturnUrl(process.env.PUBLIC_BASE_URL)) {
    const base = process.env.PUBLIC_BASE_URL.replace(/\/$/, '');
    return `${base}/api/payments/pawapay/return`;
  }

  const requestOrigin = req.get('origin');
  if (isValidPawapayReturnUrl(requestOrigin)) {
    return `${requestOrigin.replace(/\/$/, '')}/payment-return`;
  }

  return null;
}

async function createPawapayPaymentPage({
  req,
  commande,
  telephone,
  returnUrl,
}) {
  const normalizedPhone = normalizePhoneNumber(telephone);
  if (!normalizedPhone) {
    throw new Error('Numero de telephone invalide');
  }

  const resolvedReturnUrl = resolvePaymentPageReturnUrl(req, returnUrl);
  if (!resolvedReturnUrl) {
    throw new Error(
      'returnUrl invalide. Utilisez une URL HTTPS publique (pas localhost) via return_url, PAWAPAY_RETURN_URL ou PUBLIC_BASE_URL.'
    );
  }

  const currency = process.env.PAWAPAY_CURRENCY || 'XOF';
  const country = (process.env.PAWAPAY_COUNTRY || 'SEN').toUpperCase();
  const language = (process.env.PAWAPAY_LANGUAGE || 'FR').toUpperCase();
  const depositId = crypto.randomUUID();
  const clientReferenceId = commande.numero_commande || String(commande._id);
  const customerMessage = buildCustomerMessage(clientReferenceId);

  const payload = {
    depositId,
    returnUrl: resolvedReturnUrl,
    customerMessage,
    amountDetails: {
      amount: Number(commande.montant_total).toFixed(2),
      currency,
    },
    phoneNumber: normalizedPhone,
    language,
    country,
    reason: buildCustomerMessage(`CMD${clientReferenceId}`).slice(0, 22),
    metadata: [
      { orderId: clientReferenceId },
      { commandeId: String(commande._id) },
    ],
  };

  const apiResponse = await callPawapay('/v2/paymentpage', payload);
  const redirectUrl =
    apiResponse?.redirectUrl ||
    apiResponse?.redirectURL ||
    apiResponse?.url ||
    null;

  return {
    depositId,
    normalizedPhone,
    redirectUrl,
    returnUrl: resolvedReturnUrl,
    apiResponse,
  };
}

async function createPawapayDeposit({ commande, modePaiement, telephone }) {
  const normalizedPhone = normalizePhoneNumber(telephone);
  if (!normalizedPhone) {
    throw new Error('Numero de telephone invalide');
  }

  const provider = resolveProvider(modePaiement);
  if (!provider) {
    throw new Error(
      `Provider pawaPay non configure pour le mode ${modePaiement}. Configurez PAWAPAY_PROVIDER ou PAWAPAY_PROVIDER_WAVE/PAWAPAY_PROVIDER_OM.`
    );
  }

  const currency = process.env.PAWAPAY_CURRENCY || 'XOF';
  const depositId = crypto.randomUUID();
  const clientReferenceId = commande.numero_commande || String(commande._id);
  const customerMessage = buildCustomerMessage(clientReferenceId);

  const payload = {
    depositId,
    amount: Number(commande.montant_total).toFixed(2),
    currency,
    payer: {
      type: 'MMO',
      accountDetails: {
        phoneNumber: normalizedPhone,
        provider,
      },
    },
    clientReferenceId,
    customerMessage,
    metadata: [
      {
        fieldName: 'reference_paiement',
        fieldValue: depositId,
        isPII: false,
      },
      {
        fieldName: 'numero_commande',
        fieldValue: clientReferenceId,
        isPII: false,
      },
    ],
  };

  const responseBody = await callPawapay('/v2/deposits', payload);

  return {
    depositId,
    provider,
    normalizedPhone,
    apiResponse: responseBody,
  };
}

// Creer une commande
exports.createCommande = async (req, res) => {
  try {
    if (req.userType !== 'client') {
      return res.status(403).json({
        error: 'Seuls les clients peuvent creer des commandes',
      });
    }

    const {
      items,
      sous_total,
      frais_livraison,
      montant_total,
      mode_paiement,
      adresse_livraison,
    } = req.body;

    const commande = new Commande({
      id_client: req.userId,
      items,
      sous_total,
      frais_livraison: frais_livraison || 1500,
      montant_total,
      mode_paiement,
      adresse_livraison,
      statut: 'en_attente',
      statut_paiement: 'en_attente',
    });

    await commande.save();

    await commande.populate([
      { path: 'items.id_modele' },
      { path: 'items.tissus.id_tissu' },
      { path: 'items.id_mesure' },
    ]);

    return res.status(201).json({
      message: 'Commande creee avec succes',
      commande,
    });
  } catch (error) {
    console.error('Erreur lors de la creation de la commande:', error);
    return res.status(500).json({ error: error.message });
  }
};

// Initier un paiement mobile money via pawaPay.
exports.processPayment = async (req, res) => {
  try {
    const {
      commandeId,
      mode_paiement,
      telephone,
      payment_flow,
      return_url,
      cancel_url,
    } = req.body;

    const selectedFlow =
      String(payment_flow || process.env.PAWAPAY_PAYMENT_FLOW || 'payment_page')
        .trim()
        .toLowerCase();

    if (!commandeId || !mode_paiement || !telephone) {
      return res.status(400).json({
        error: 'commandeId, mode_paiement et telephone sont obligatoires',
      });
    }

    if (!['wave', 'orange_money'].includes(mode_paiement)) {
      return res.status(400).json({
        error: 'Mode de paiement non supporte pour pawaPay',
      });
    }

    const commande = await Commande.findById(commandeId);
    if (!commande) {
      return res.status(404).json({ error: 'Commande non trouvee' });
    }

    if (commande.id_client.toString() !== req.userId.toString()) {
      return res.status(403).json({ error: 'Non autorise' });
    }

    if (commande.statut_paiement === 'paye') {
      return res.status(400).json({ error: 'Cette commande est deja payee' });
    }

    if (commande.statut_paiement === 'en_attente' && commande.reference_paiement) {
      return res.status(409).json({
        error: 'Un paiement est deja en cours pour cette commande',
        reference: commande.reference_paiement,
      });
    }

    const paymentResult =
      selectedFlow === 'direct_deposit'
        ? await createPawapayDeposit({
            commande,
            modePaiement: mode_paiement,
            telephone,
          })
        : await createPawapayPaymentPage({
            req,
            commande,
            telephone,
            returnUrl: return_url,
          });

    commande.mode_paiement = mode_paiement;
    commande.reference_paiement = paymentResult.depositId;
    commande.statut_paiement = 'en_attente';
    await commande.save();

    await commande.populate([
      { path: 'items.id_modele' },
      { path: 'items.tissus.id_tissu' },
      { path: 'items.id_mesure' },
    ]);

    return res.json({
      message:
        selectedFlow === 'direct_deposit'
          ? 'Demande de paiement envoyee. Validez sur votre telephone.'
          : 'Session de paiement pawaPay creee. Finalisez le paiement dans la popup.',
      commande,
      reference: commande.reference_paiement,
      payment_flow: selectedFlow,
      redirect_url: paymentResult.redirectUrl || null,
      return_url: paymentResult.returnUrl || null,
      payment: {
        provider: paymentResult.provider || null,
        phoneNumber: paymentResult.normalizedPhone,
        status: paymentResult.apiResponse?.status || 'submitted',
      },
    });
  } catch (error) {
    console.error('Erreur lors du paiement:', error);

    const message = String(error?.message || 'Erreur paiement');
    const upstreamCodeMatch = message.match(/Echec pawaPay \((\d{3})\)/);
    if (upstreamCodeMatch) {
      const upstreamCode = Number(upstreamCodeMatch[1]);
      return res.status(upstreamCode >= 500 ? 502 : 400).json({ error: message });
    }

    if (
      message.includes('PAWAPAY_') ||
      message.includes('Provider pawaPay') ||
      message.includes('telephone invalide') ||
      message.includes('returnUrl invalide')
    ) {
      return res.status(400).json({ error: message });
    }

    return res.status(500).json({ error: message });
  }
};

// Recuperer les commandes du client
exports.getCommandesByClient = async (req, res) => {
  try {
    const filter = req.userType === 'admin' ? {} : { id_client: req.userId };

    const commandes = await Commande.find(filter)
      .populate([
        { path: 'items.id_modele' },
        { path: 'items.tissus.id_tissu' },
        { path: 'items.id_mesure' },
        { path: 'id_client', select: 'prenom nom username email telephone' },
      ])
      .sort({ createdAt: -1 });

    return res.json({
      commandes,
      total: commandes.length,
    });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.updateCommandeStatus = async (req, res) => {
  try {
    if (req.userType !== 'admin') {
      return res.status(403).json({ error: 'Acces reserve aux admins' });
    }

    const { statut, statut_paiement, notes_admin } = req.body;

    const commande = await Commande.findByIdAndUpdate(
      req.params.id,
      { statut, statut_paiement, notes_admin },
      { new: true }
    );

    if (!commande) {
      return res.status(404).json({ error: 'Commande non trouvee' });
    }

    return res.json({ message: 'Commande mise a jour', commande });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

// Recuperer une commande par ID
exports.getCommandeById = async (req, res) => {
  try {
    const commande = await Commande.findById(req.params.id).populate([
      { path: 'items.id_modele' },
      { path: 'items.tissus.id_tissu' },
      { path: 'items.id_mesure' },
      { path: 'id_client' },
    ]);

    if (!commande) {
      return res.status(404).json({ error: 'Commande non trouvee' });
    }

    if (commande.id_client._id.toString() !== req.userId.toString() && req.userType !== 'admin') {
      return res.status(403).json({ error: 'Non autorise' });
    }

    return res.json(commande);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};
