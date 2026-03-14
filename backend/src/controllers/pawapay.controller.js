const crypto = require('crypto');
const Commande = require('../models/Commande');
const PawapayCallbackEvent = require('../models/PawapayCallbackEvent');

const SUCCESS_STATUSES = new Set([
  'completed',
  'successful',
  'succeeded',
  'success',
  'accepted',
  'processed',
  'delivered',
]);

const FAILURE_STATUSES = new Set([
  'failed',
  'rejected',
  'cancelled',
  'expired',
  'aborted',
  'error',
]);

function toCleanString(value) {
  if (value == null) return null;
  const text = String(value).trim();
  return text.length ? text : null;
}

function normalizeStatus(payload) {
  const raw =
    payload?.status ??
    payload?.state ??
    payload?.resultStatus ??
    payload?.transactionStatus ??
    'unknown';

  return String(raw).trim().toLowerCase();
}

function payloadHash(payload) {
  return crypto
    .createHash('sha256')
    .update(JSON.stringify(payload || {}))
    .digest('hex')
    .slice(0, 24);
}

function extractExternalId(callbackType, payload) {
  const byType = {
    deposits: [
      payload?.depositId,
      payload?.deposit_id,
      payload?.id,
      payload?.transactionId,
      payload?.providerTransactionId,
    ],
    payouts: [
      payload?.payoutId,
      payload?.payout_id,
      payload?.id,
      payload?.transactionId,
      payload?.providerTransactionId,
    ],
    refunds: [
      payload?.refundId,
      payload?.refund_id,
      payload?.id,
      payload?.transactionId,
      payload?.providerTransactionId,
    ],
  };

  const candidate = (byType[callbackType] || [])
    .map(toCleanString)
    .find(Boolean);

  return candidate || `payload_${payloadHash(payload)}`;
}

function extractReferenceCandidates(callbackType, payload, externalId) {
  const metadata = payload?.metadata && typeof payload.metadata === 'object'
    ? payload.metadata
    : {};

  const rawCandidates = [
    payload?.reference_paiement,
    payload?.referencePaiement,
    payload?.reference,
    payload?.merchantReference,
    payload?.merchantTransactionId,
    payload?.merchantId,
    payload?.orderId,
    payload?.statementDescription,
    payload?.customerReference,
    payload?.depositId,
    payload?.payoutId,
    payload?.refundId,
    externalId,
    metadata?.reference_paiement,
    metadata?.numero_commande,
    metadata?.commande_id,
    metadata?.commandeId,
    metadata?.order_id,
    metadata?.orderId,
  ];

  const cleaned = rawCandidates
    .map(toCleanString)
    .filter(Boolean);

  return [...new Set(cleaned)];
}

async function updateCommandeFromCallback({
  callbackType,
  status,
  referenceCandidates,
  externalId,
}) {
  const refCandidates = [...referenceCandidates];
  if (!refCandidates.includes(externalId)) {
    refCandidates.push(externalId);
  }

  const commande = await Commande.findOne({
    $or: [
      { reference_paiement: { $in: refCandidates } },
      { numero_commande: { $in: refCandidates } },
    ],
  });

  if (!commande) {
    return {
      matched_commande: false,
      updated_commande: false,
      payment_status_applied: null,
      message: 'Aucune commande correspondante',
      commande_id: null,
    };
  }

  let paymentStatusToApply = null;
  if (callbackType === 'refunds') {
    if (SUCCESS_STATUSES.has(status)) {
      paymentStatusToApply = 'rembourse';
    }
  } else {
    if (SUCCESS_STATUSES.has(status)) {
      paymentStatusToApply = 'paye';
    } else if (FAILURE_STATUSES.has(status)) {
      paymentStatusToApply = 'echoue';
    }
  }

  let updated = false;
  if (paymentStatusToApply && commande.statut_paiement !== paymentStatusToApply) {
    commande.statut_paiement = paymentStatusToApply;
    updated = true;
  }

  if (
    paymentStatusToApply === 'paye' &&
    commande.statut === 'en_attente'
  ) {
    commande.statut = 'confirmee';
    if (commande.statut_commande === 'en_attente') {
      commande.statut_commande = 'en_cours';
    }
    updated = true;
  }

  if (!commande.reference_paiement) {
    commande.reference_paiement = externalId;
    updated = true;
  }

  if (updated) {
    await commande.save();
  }

  return {
    matched_commande: true,
    updated_commande: updated,
    payment_status_applied: paymentStatusToApply,
    message: updated
      ? 'Commande mise a jour avec le callback'
      : 'Commande trouvee sans changement necessaire',
    commande_id: commande._id,
  };
}

async function processPawapayCallback(callbackType, req, res) {
  try {
    const payload = req.body || {};
    const status = normalizeStatus(payload);
    const externalId = extractExternalId(callbackType, payload);
    const dedupeKey = `${callbackType}:${externalId}:${status}`;
    const referenceCandidates = extractReferenceCandidates(
      callbackType,
      payload,
      externalId
    );

    const headers = {
      'user-agent': req.get('user-agent') || null,
      'content-type': req.get('content-type') || null,
      'x-forwarded-for': req.get('x-forwarded-for') || null,
      'x-real-ip': req.get('x-real-ip') || null,
    };

    let callbackEvent;
    try {
      callbackEvent = await PawapayCallbackEvent.create({
        callback_type: callbackType,
        external_id: externalId,
        status,
        dedupe_key: dedupeKey,
        reference_candidates: referenceCandidates,
        payload,
        headers,
        last_received_at: new Date(),
      });
    } catch (error) {
      // Duplicata callback: idempotence.
      if (error?.code === 11000) {
        await PawapayCallbackEvent.updateOne(
          { dedupe_key: dedupeKey },
          {
            $inc: { duplicate_count: 1 },
            $set: { last_received_at: new Date() },
          }
        );

        return res.status(200).json({
          received: true,
          duplicate: true,
          callback_type: callbackType,
          external_id: externalId,
          status,
        });
      }
      throw error;
    }

    const processingResult = await updateCommandeFromCallback({
      callbackType,
      status,
      referenceCandidates,
      externalId,
    });

    callbackEvent.commande_id = processingResult.commande_id;
    callbackEvent.processing = {
      matched_commande: processingResult.matched_commande,
      updated_commande: processingResult.updated_commande,
      payment_status_applied: processingResult.payment_status_applied,
      message: processingResult.message,
    };
    callbackEvent.processed_at = new Date();
    await callbackEvent.save();

    return res.status(200).json({
      received: true,
      duplicate: false,
      callback_type: callbackType,
      external_id: externalId,
      status,
      matched_commande: processingResult.matched_commande,
      updated_commande: processingResult.updated_commande,
    });
  } catch (error) {
    console.error(`Erreur callback pawaPay (${callbackType}):`, error);
    return res.status(500).json({
      error: 'Erreur traitement callback pawaPay',
      details: error.message,
    });
  }
}

exports.depositCallback = async (req, res) =>
  processPawapayCallback('deposits', req, res);

exports.payoutCallback = async (req, res) =>
  processPawapayCallback('payouts', req, res);

exports.refundCallback = async (req, res) =>
  processPawapayCallback('refunds', req, res);

exports.callbackHealth = async (req, res) => {
  res.status(200).json({
    service: 'pawapay-callbacks',
    status: 'ok',
    timestamp: new Date().toISOString(),
  });
};
