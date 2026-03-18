'use client';

import { Fragment, useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import NavBar from '@/components/NavBar';
import RequireAdmin from '@/components/RequireAdmin';
import { apiRequest, uploadSingleImage, uploadSingleVideo } from '@/lib/api';
import {
  FINANCE_STORAGE_KEY,
  ORDERS_STORAGE_KEY,
  createSeedFinance,
  createSeedOrders,
  loadStoredData,
  saveStoredData,
} from '@/lib/erpStorage';

const STATUTS_SUIVI = [
  { value: 'en_attente', label: 'Validation' },
  { value: 'confirmee', label: 'Commande en tissus' },
  { value: 'en_cours', label: 'Chez le tailleur' },
  { value: 'prete', label: 'Repassage' },
  { value: 'terminee', label: 'Termine' },
];

const STATUTS_COMMANDE = [
  { value: 'en_attente', label: 'En attente' },
  { value: 'en_cours', label: 'En cours' },
  { value: 'terminee', label: 'Terminee' },
  { value: 'annulee', label: 'Annulee' },
];

const RETOUR_STATUTS = [
  { value: 'demande', label: 'Demande' },
  { value: 'en_traitement', label: 'En traitement' },
  { value: 'resolu', label: 'Resolu' },
  { value: 'rejete', label: 'Rejete' },
];

const PAYMENT_STATUSES = [
  { value: 'en_attente', label: 'En attente' },
  { value: 'paye', label: 'Payee' },
  { value: 'rembourse', label: 'Remboursee' },
  { value: 'echoue', label: 'Echoue' },
];

function normalizeStatutCommande(commande) {
  const raw = (commande?.statut_commande || '').toLowerCase();
  if (raw) return raw;
  const step = (commande?.statut || '').toLowerCase();
  if (['livree', 'terminee', 'termine'].includes(step)) return 'terminee';
  if (step === 'annulee') return 'annulee';
  if (step === 'en_attente') return 'en_attente';
  return 'en_cours';
}

function normalizeSuivi(value) {
  const raw = String(value || '').toLowerCase();
  if (['livree', 'terminee', 'termine'].includes(raw)) return 'terminee';
  return raw;
}

function getSuiviLabel(value) {
  const normalized = normalizeSuivi(value);
  const found = STATUTS_SUIVI.find((item) => item.value === normalized);
  return found ? found.label : value || 'Validation';
}

function getNextSuiviValue(value) {
  const normalized = normalizeSuivi(value);
  if (normalized === 'annulee') return null;
  const flow = STATUTS_SUIVI.map((item) => item.value);
  const idx = flow.indexOf(normalized);
  if (idx === -1) return flow[0];
  if (idx >= flow.length - 1) return null;
  return flow[idx + 1];
}

function getPrevSuiviValue(value) {
  const normalized = normalizeSuivi(value);
  if (normalized === 'annulee') return null;
  const flow = STATUTS_SUIVI.map((item) => item.value);
  const idx = flow.indexOf(normalized);
  if (idx <= 0) return null;
  return flow[idx - 1];
}

function toDateInputValue(value) {
  if (!value) return '';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '';
  return date.toISOString().slice(0, 10);
}

function formatDate(value) {
  if (!value) return '-';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '-';
  return date.toLocaleDateString('fr-FR');
}

function parseUrls(text) {
  if (!text) return [];
  return text
    .split(/[,\n]/)
    .map((item) => item.trim())
    .filter(Boolean);
}

function todayString() {
  return new Date().toISOString().slice(0, 10);
}

function toNumber(value) {
  const amount = Number(value);
  return Number.isFinite(amount) ? amount : 0;
}

function computeCommandeSupplierCost(commande) {
  if (!commande) return 0;
  const items = Array.isArray(commande.items) ? commande.items : [];
  return items.reduce((sum, item) => {
    const quantite = toNumber(item?.quantite || item?.qte || 1) || 1;
    const modeleCost = toNumber(item?.id_modele?.prix_fournisseur);
    let total = modeleCost * quantite;

    const tissus = Array.isArray(item?.tissus) ? item.tissus : [];
    tissus.forEach((tissu) => {
      const metrage = toNumber(tissu?.metrage || tissu?.quantite || 0);
      const tissuCost = toNumber(tissu?.id_tissu?.prix_fournisseur);
      total += tissuCost * metrage;
    });

    return sum + total;
  }, 0);
}

function computeBenefice(total, fournisseur) {
  return toNumber(total) - toNumber(fournisseur);
}

function buildManualOrderForm(category) {
  return {
    category,
    article: '',
    type_unite: 'metre',
    quantite: '',
    client: '',
    montant_total: '',
    prix_fournisseur: '',
    justificatif: '',
    date_commande: todayString(),
    date_livraison_estimee: '',
    statut: 'en_attente',
    statut_commande: 'en_attente',
    statut_paiement: 'en_attente',
    note: '',
    mode_paiement: 'especes',
  };
}

function createManualOrderNumber(category) {
  const prefix = category === 'tissus' ? 'TIS' : category === 'pret_a_porter' ? 'PAP' : 'SM';
  const stamp = new Date().toISOString().slice(2, 10).replace(/-/g, '');
  const unique = String(Date.now()).slice(-4);
  return `${prefix}-${stamp}-${unique}`;
}

function buildFinanceEntry({ source, sourceId, type, label, montant, date, payeur, mode }) {
  return {
    id: `ent-${Date.now()}-${sourceId}`,
    type,
    label,
    montant: toNumber(montant),
    date: date || todayString(),
    payeur: payeur || '',
    mode: mode || 'especes',
    statut: 'paye',
    justificatif: '',
    source,
    sourceId,
  };
}

function buildSupplierExpense({ source, sourceId, label, montant, date, beneficiaire }) {
  return {
    id: `exp-${Date.now()}-${sourceId}`,
    type: 'fournisseur',
    label,
    montant: toNumber(montant),
    date: date || todayString(),
    beneficiaire: beneficiaire || 'Fournisseur',
    mode: 'virement',
    statut: 'a_payer',
    justificatif: '',
    source,
    sourceId,
  };
}

function commitFinanceEntry(entry) {
  const finance = loadStoredData(FINANCE_STORAGE_KEY, createSeedFinance);
  const exists = finance.entries.some((item) => item.source === entry.source && item.sourceId === entry.sourceId);
  if (exists) return;
  finance.entries = [entry, ...finance.entries];
  saveStoredData(FINANCE_STORAGE_KEY, finance);
}

function commitFinanceExpense(expense) {
  const finance = loadStoredData(FINANCE_STORAGE_KEY, createSeedFinance);
  const exists = finance.expenses.some((item) => item.source === expense.source && item.sourceId === expense.sourceId);
  if (exists) return;
  finance.expenses = [expense, ...finance.expenses];
  saveStoredData(FINANCE_STORAGE_KEY, finance);
}

function syncSurMesureEntries(commandes) {
  const finance = loadStoredData(FINANCE_STORAGE_KEY, createSeedFinance);
  const existingEntryKeys = new Set(
    finance.entries.map((entry) => `${entry.source || ''}:${entry.sourceId || ''}`)
  );
  const existingExpenseKeys = new Set(
    finance.expenses.map((expense) => `${expense.source || ''}:${expense.sourceId || ''}`)
  );
  let changed = false;

  commandes.forEach((commande) => {
    if (normalizeStatutCommande(commande) !== 'terminee') return;
    const key = `sur_mesure:${commande._id}`;
    const clientName = `${commande.id_client?.prenom || ''} ${commande.id_client?.nom || ''}`.trim();
    const supplierCost = computeCommandeSupplierCost(commande);
    const benefice = computeBenefice(commande.montant_total, supplierCost);
    const entry = buildFinanceEntry({
      source: 'sur_mesure',
      sourceId: commande._id,
      type: 'sur_mesure',
      label: `Commande ${commande.numero_commande}`,
      montant: benefice,
      date: commande.date_livraison_estimee || commande.createdAt?.slice(0, 10),
      payeur: clientName,
      mode: commande.mode_paiement,
    });
    if (!existingEntryKeys.has(key)) {
      finance.entries = [entry, ...finance.entries];
      existingEntryKeys.add(key);
      changed = true;
    }
    if (supplierCost > 0 && !existingExpenseKeys.has(key)) {
      const expense = buildSupplierExpense({
        source: 'sur_mesure',
        sourceId: commande._id,
        label: `Paiement fournisseur ${commande.numero_commande}`,
        montant: supplierCost,
        date: commande.date_livraison_estimee || commande.createdAt?.slice(0, 10),
        beneficiaire: 'Fournisseur',
      });
      finance.expenses = [expense, ...finance.expenses];
      existingExpenseKeys.add(key);
      changed = true;
    }
  });

  if (changed) {
    saveStoredData(FINANCE_STORAGE_KEY, finance);
  }
}

export default function CommandesPage() {
  const [commandes, setCommandes] = useState([]);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [activeTab, setActiveTab] = useState('');
  const [manualOrders, setManualOrders] = useState(createSeedOrders());
  const [showManualModal, setShowManualModal] = useState(false);
  const [manualForm, setManualForm] = useState(buildManualOrderForm('tissus'));
  const [manualError, setManualError] = useState('');
  const [manualUploading, setManualUploading] = useState(false);
  const [openResultatId, setOpenResultatId] = useState(null);
  const [resultatDrafts, setResultatDrafts] = useState({});
  const [detailCommande, setDetailCommande] = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [detailError, setDetailError] = useState('');

  const searchParams = useSearchParams();
  const tabParam = searchParams.get('tab');

  const dateText = useMemo(
    () =>
      new Date().toLocaleDateString('fr-FR', {
        weekday: 'long',
        day: 'numeric',
        month: 'long',
        year: 'numeric',
      }),
    []
  );

  const loadCommandes = async () => {
    try {
      const data = await apiRequest('/api/commandes');
      const list = data.commandes || [];
      syncSurMesureEntries(list);
      setCommandes(list);
      setError('');
    } catch (err) {
      setError(err.message);
    }
  };

  useEffect(() => {
    loadCommandes();
  }, []);

  useEffect(() => {
    if (['sur_mesure', 'tissus', 'pret_a_porter'].includes(tabParam)) {
      setActiveTab(tabParam);
    } else {
      setActiveTab('');
    }
  }, [tabParam]);

  useEffect(() => {
    setManualOrders(loadStoredData(ORDERS_STORAGE_KEY, createSeedOrders));
  }, []);

  useEffect(() => {
    saveStoredData(ORDERS_STORAGE_KEY, manualOrders);
  }, [manualOrders]);

  const manualOrdersByTab = {
    sur_mesure: manualOrders.sur_mesure || [],
    tissus: manualOrders.tissus || [],
    pret_a_porter: manualOrders.pret_a_porter || [],
  };

  const combinedSurMesure = [
    ...manualOrdersByTab.sur_mesure.map((order) => ({ ...order, source: 'manual' })),
    ...commandes,
  ];

  const filtered = combinedSurMesure.filter((item) => {
    const numero = String(item.numero_commande || '').toLowerCase();
    const client = item.source === 'manual'
      ? String(item.client || '').toLowerCase()
      : `${item.id_client?.prenom || ''} ${item.id_client?.nom || ''}`.toLowerCase();
    return numero.includes(search.toLowerCase()) || client.includes(search.toLowerCase());
  });

  const manualList = manualOrdersByTab[activeTab] || [];
  const filteredManual = manualList.filter((item) => {
    const client = String(item.client || '').toLowerCase();
    return item.numero_commande?.toLowerCase().includes(search.toLowerCase()) || client.includes(search.toLowerCase());
  });

  const suiviCounts = STATUTS_SUIVI.reduce((acc, item) => {
    const total = combinedSurMesure.filter((c) => normalizeSuivi(c.statut) === item.value).length;
    acc[item.value] = total;
    return acc;
  }, {});

  const isSurMesureTab = activeTab === 'sur_mesure';
  const isTissuTab = activeTab === 'tissus';
  const isPretTab = activeTab === 'pret_a_porter';
  const totalCount = !activeTab ? 0 : isSurMesureTab ? filtered.length : filteredManual.length;
  const manualBenefice = computeBenefice(manualForm.montant_total, manualForm.prix_fournisseur);
  const manualUnitLabel = manualForm.type_unite === 'piece' ? 'pieces' : 'metres';
  const manualItemLabel = isSurMesureTab ? 'Modele / description' : isTissuTab ? 'Tissu' : 'Produit';

  const updateSuivi = async (id, statut) => {
    await apiRequest(`/api/commandes/${id}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ statut }),
    });
    loadCommandes();
  };

  const updateStatutCommande = async (commande, statut_commande) => {
    await apiRequest(`/api/commandes/${commande._id}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ statut_commande }),
    });
    if (statut_commande === 'terminee') {
      const clientName = `${commande.id_client?.prenom || ''} ${commande.id_client?.nom || ''}`.trim();
      const supplierCost = computeCommandeSupplierCost(commande);
      const benefice = computeBenefice(commande.montant_total, supplierCost);
      const entry = buildFinanceEntry({
        source: 'sur_mesure',
        sourceId: commande._id,
        type: 'sur_mesure',
        label: `Commande ${commande.numero_commande}`,
        montant: benefice,
        date: commande.date_livraison_estimee || commande.createdAt?.slice(0, 10),
        payeur: clientName,
        mode: commande.mode_paiement,
      });
      commitFinanceEntry(entry);
      if (supplierCost > 0) {
        const expense = buildSupplierExpense({
          source: 'sur_mesure',
          sourceId: commande._id,
          label: `Paiement fournisseur ${commande.numero_commande}`,
          montant: supplierCost,
          date: commande.date_livraison_estimee || commande.createdAt?.slice(0, 10),
          beneficiaire: 'Fournisseur',
        });
        commitFinanceExpense(expense);
      }
    }
    loadCommandes();
  };

  const updateDeliveryDate = async (id, dateValue) => {
    await apiRequest(`/api/commandes/${id}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ date_livraison_estimee: dateValue || null }),
    });
    loadCommandes();
  };

  const openManualModalForm = () => {
    const nextForm = buildManualOrderForm(activeTab);
    if (activeTab === 'pret_a_porter') {
      nextForm.type_unite = 'piece';
    }
    setManualForm(nextForm);
    setManualError('');
    setManualUploading(false);
    setShowManualModal(true);
  };

  const closeManualModalForm = () => {
    setShowManualModal(false);
    setManualError('');
    setManualUploading(false);
  };

  const updateManualField = (field, value) => {
    setManualForm((prev) => ({ ...prev, [field]: value }));
  };

  const uploadManualJustificatif = async (file) => {
    if (!file) return;
    setManualUploading(true);
    setManualError('');
    try {
      const result = await uploadSingleImage(file);
      if (result?.image?.url) {
        setManualForm((prev) => ({ ...prev, justificatif: result.image.url }));
      }
    } catch (err) {
      setManualError(err.message);
    } finally {
      setManualUploading(false);
    }
  };

  const addManualFinanceEntries = (order) => {
    const category = order.category || activeTab;
    const entryType =
      category === 'tissus' ? 'tissu' : category === 'pret_a_porter' ? 'pret_a_porter' : 'sur_mesure';
    const supplierCost = toNumber(order.prix_fournisseur);
    const benefice = computeBenefice(order.montant_total, supplierCost);
    const entry = buildFinanceEntry({
      source: category,
      sourceId: order.id,
      type: entryType,
      label: `Commande ${order.numero_commande}`,
      montant: benefice,
      date: order.date_commande,
      payeur: order.client,
      mode: order.mode_paiement,
    });
    commitFinanceEntry(entry);
    if (supplierCost > 0) {
      const expense = buildSupplierExpense({
        source: category,
        sourceId: order.id,
        label: `Paiement fournisseur ${order.numero_commande}`,
        montant: supplierCost,
        date: order.date_commande,
        beneficiaire: 'Fournisseur',
      });
      commitFinanceExpense(expense);
    }
  };

  const saveManualOrder = () => {
    const category = manualForm.category;
    const requiresArticle = category !== 'sur_mesure';
    const requiresQuantite = category !== 'sur_mesure';
    if (
      !manualForm.client ||
      !manualForm.montant_total ||
      (requiresArticle && !manualForm.article) ||
      (requiresQuantite && !manualForm.quantite)
    ) {
      setManualError('Renseigne le client, le produit, la quantite et le montant.');
      return;
    }
    if (!manualForm.prix_fournisseur) {
      setManualError('Renseigne le prix fournisseur pour calculer le benefice.');
      return;
    }

    const benefice = computeBenefice(manualForm.montant_total, manualForm.prix_fournisseur);
    const newOrder = {
      id: `${category}-${Date.now()}`,
      numero_commande: createManualOrderNumber(category),
      article: manualForm.article,
      type_unite: manualForm.type_unite,
      quantite: toNumber(manualForm.quantite),
      client: manualForm.client,
      montant_total: toNumber(manualForm.montant_total),
      prix_fournisseur: toNumber(manualForm.prix_fournisseur),
      benefice,
      justificatif: manualForm.justificatif || '',
      date_commande: manualForm.date_commande || todayString(),
      date_livraison_estimee: manualForm.date_livraison_estimee || '',
      statut: manualForm.statut || 'en_attente',
      statut_commande: manualForm.statut_commande,
      statut_paiement: manualForm.statut_paiement,
      note: manualForm.note || '',
      mode_paiement: manualForm.mode_paiement || 'especes',
      category,
    };

    setManualOrders((prev) => ({
      ...prev,
      [category]: [newOrder, ...(prev[category] || [])],
    }));

    if (category === 'sur_mesure') {
      if (newOrder.statut_commande === 'terminee') {
        addManualFinanceEntries(newOrder);
      }
    } else {
      addManualFinanceEntries(newOrder);
    }

    setShowManualModal(false);
    setManualError('');
  };

  const updateManualOrderStatus = (orderId, nextStatus) => {
    const category = activeTab;
    const currentOrder = manualList.find((order) => order.id === orderId);
    setManualOrders((prev) => ({
      ...prev,
      [category]: (prev[category] || []).map((order) =>
        order.id === orderId ? { ...order, statut_commande: nextStatus } : order
      ),
    }));

    if (currentOrder && nextStatus === 'terminee' && currentOrder.category === 'sur_mesure') {
      addManualFinanceEntries({ ...currentOrder, statut_commande: nextStatus });
    }
  };

  const updateManualPaymentStatus = (orderId, nextStatus) => {
    const category = activeTab;
    setManualOrders((prev) => ({
      ...prev,
      [category]: (prev[category] || []).map((order) =>
        order.id === orderId ? { ...order, statut_paiement: nextStatus } : order
      ),
    }));
  };

  const updateManualDeliveryDate = (orderId, dateValue) => {
    const category = activeTab;
    setManualOrders((prev) => ({
      ...prev,
      [category]: (prev[category] || []).map((order) =>
        order.id === orderId ? { ...order, date_livraison_estimee: dateValue } : order
      ),
    }));
  };

  const updateManualSuivi = (orderId, statut) => {
    setManualOrders((prev) => ({
      ...prev,
      sur_mesure: (prev.sur_mesure || []).map((order) =>
        order.id === orderId ? { ...order, statut } : order
      ),
    }));
  };

  const updateRetourStatus = async (commandeId, retourId, statut) => {
    await apiRequest(`/api/commandes/${commandeId}/retours/${retourId}`, {
      method: 'PATCH',
      body: JSON.stringify({ statut }),
    });
    loadCommandes();
  };

  const openDetails = async (commandeId) => {
    setDetailLoading(true);
    setDetailError('');
    setDetailCommande(null);
    try {
      const data = await apiRequest(`/api/commandes/${commandeId}`);
      setDetailCommande(data);
    } catch (err) {
      setDetailError(err.message);
    } finally {
      setDetailLoading(false);
    }
  };

  const closeDetails = () => {
    setDetailCommande(null);
    setDetailError('');
    setDetailLoading(false);
  };

  const markPaymentAsPaid = async (id) => {
    const confirmMark = window.confirm('Confirmer la validation du paiement ?');
    if (!confirmMark) return;
    await apiRequest(`/api/commandes/${id}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ statut_paiement: 'paye' }),
    });
    loadCommandes();
  };

  const toggleResultat = (commande) => {
    const id = commande._id || commande.id;
    if (openResultatId === id) {
      setOpenResultatId(null);
      return;
    }

    setOpenResultatId(id);
    setResultatDrafts((prev) => {
      if (prev[id]) return prev;
      const photos = commande.resultat_couture?.photos?.join('\n') || '';
      const videos = commande.resultat_couture?.videos?.join('\n') || '';
      return {
        ...prev,
        [id]: { photos, videos, saving: false, error: '', uploadingImages: false, uploadingVideos: false },
      };
    });
  };

  const updateDraft = (id, field, value) => {
    setResultatDrafts((prev) => ({
      ...prev,
      [id]: { ...prev[id], [field]: value },
    }));
  };

  const appendDraftUrl = (id, field, url) => {
    setResultatDrafts((prev) => {
      const current = prev[id]?.[field] || '';
      const next = current ? `${current}\n${url}` : url;
      return {
        ...prev,
        [id]: { ...prev[id], [field]: next },
      };
    });
  };

  const setDraftUploading = (id, field, value) => {
    setResultatDrafts((prev) => ({
      ...prev,
      [id]: { ...prev[id], [field]: value },
    }));
  };

  const uploadImages = async (commandeId, files) => {
    if (!files || files.length === 0) return;
    setDraftUploading(commandeId, 'uploadingImages', true);
    try {
      for (const file of Array.from(files)) {
        const result = await uploadSingleImage(file);
        if (result?.image?.url) {
          appendDraftUrl(commandeId, 'photos', result.image.url);
        }
      }
    } catch (err) {
      setResultatDrafts((prev) => ({
        ...prev,
        [commandeId]: { ...prev[commandeId], error: err.message },
      }));
    } finally {
      setDraftUploading(commandeId, 'uploadingImages', false);
    }
  };

  const uploadVideos = async (commandeId, files) => {
    if (!files || files.length === 0) return;
    setDraftUploading(commandeId, 'uploadingVideos', true);
    try {
      for (const file of Array.from(files)) {
        const result = await uploadSingleVideo(file);
        if (result?.video?.url) {
          appendDraftUrl(commandeId, 'videos', result.video.url);
        }
      }
    } catch (err) {
      setResultatDrafts((prev) => ({
        ...prev,
        [commandeId]: { ...prev[commandeId], error: err.message },
      }));
    } finally {
      setDraftUploading(commandeId, 'uploadingVideos', false);
    }
  };

  const saveResultat = async (commandeId) => {
    const draft = resultatDrafts[commandeId];
    if (!draft) return;

    setResultatDrafts((prev) => ({
      ...prev,
      [commandeId]: { ...prev[commandeId], saving: true, error: '' },
    }));

    try {
      await apiRequest(`/api/commandes/${commandeId}/resultat-couture`, {
        method: 'PATCH',
        body: JSON.stringify({
          photos: parseUrls(draft.photos),
          videos: parseUrls(draft.videos),
        }),
      });
      await loadCommandes();
      setOpenResultatId(null);
    } catch (err) {
      setResultatDrafts((prev) => ({
        ...prev,
        [commandeId]: { ...prev[commandeId], saving: false, error: err.message },
      }));
      return;
    }

    setResultatDrafts((prev) => ({
      ...prev,
      [commandeId]: { ...prev[commandeId], saving: false, error: '' },
    }));
  };

  return (
    <RequireAdmin>
      <main className="admin-shell">
        <NavBar />
        <section className="main">
                    <div className="topline">
            <span style={{ fontSize: 14, fontWeight: 700, color: '#7a6245' }}>Commandes</span>
            <span className="date-text">{dateText}</span>
          </div>

          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
            <div>
              <h1 className="page-title">Suivi et commandes</h1>
              <p className="subtitle">{totalCount} commandes au total</p>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              {activeTab && (
                <button className="create-modele-btn" onClick={openManualModalForm}>
                  Ajouter commande
                </button>
              )}
            </div>
          </div>

          {activeTab === 'sur_mesure' ? (
            <div className="stats-grid single-row">
              {STATUTS_SUIVI.map((item) => (
                <div className="stats-card" key={item.value}>
                  <div className="value">{suiviCounts[item.value] || 0}</div>
                  <div className="label">{item.label}</div>
                </div>
              ))}
            </div>
          ) : null}

          {activeTab ? (
            <>
              <div className="panel search-wide">
                <input placeholder="Rechercher par numero ou client..." value={search} onChange={(e) => setSearch(e.target.value)} />
              </div>

              {error ? <p className="error-text">{error}</p> : null}

              {activeTab === 'sur_mesure' ? (
            <div className="panel table-wrap" style={{ padding: 18 }}>
            <table className="table modern compact commandes-table">
              <thead>
                <tr>
                  <th>Commande</th>
                  <th>Client</th>
                  <th>Total</th>
                  <th>Livraison</th>
                  <th>Paiement</th>
                  <th>Suivi</th>
                  <th>Statut</th>
                  <th>Resultat</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((commande) => {
                  const isManual = commande.source === 'manual';
                  const commandeId = commande._id || commande.id;
                  const statutCommande = normalizeStatutCommande(commande);
                  const paiementStatutRaw = String(commande.statut_paiement || 'en_attente').toLowerCase();
                  const paiementStatut = statutCommande === 'annulee' ? 'rembourse' : paiementStatutRaw;
                  const paiementLabel = paiementStatut === 'paye'
                    ? 'Payee'
                    : paiementStatut === 'rembourse'
                      ? 'Remboursee'
                      : paiementStatut === 'echoue'
                        ? 'Echoue'
                        : 'En attente';
                  const draft = isManual ? {} : resultatDrafts[commandeId] || {};
                  const photosCount = isManual ? 0 : commande.resultat_couture?.photos?.length || 0;
                  const videosCount = isManual ? 0 : commande.resultat_couture?.videos?.length || 0;
                  const currentSuiviLabel = getSuiviLabel(commande.statut);
                  const nextSuivi = getNextSuiviValue(commande.statut);
                  const prevSuivi = getPrevSuiviValue(commande.statut);
                  const livraisonValue = toDateInputValue(commande.date_livraison_estimee);
                  const photoList = parseUrls(draft.photos || '');
                  const videoList = parseUrls(draft.videos || '');
                  const canChangeStatutCommande = statutCommande !== 'terminee';
                  const clientLabel = isManual
                    ? String(commande.client || '')
                    : `${commande.id_client?.prenom || ''} ${commande.id_client?.nom || ''}`.trim();

                  return (
                    <Fragment key={commandeId}>
                      <tr>
                        <td>
                          {isManual ? (
                            <span>{commande.numero_commande}</span>
                          ) : (
                            <button
                              type="button"
                              className="link-button"
                              onClick={() => openDetails(commandeId)}
                              title="Voir les details"
                            >
                              {commande.numero_commande}
                            </button>
                          )}
                        </td>
                        <td>
                          <span
                            className="cell-ellipsis"
                            title={clientLabel}
                          >
                            {clientLabel}
                          </span>
                        </td>
                        <td>{commande.montant_total} FCFA</td>
                        <td>
                          <input
                            type="date"
                            value={livraisonValue}
                            onChange={(e) =>
                              isManual
                                ? updateManualDeliveryDate(commandeId, e.target.value)
                                : updateDeliveryDate(commandeId, e.target.value)
                            }
                          />
                        </td>
                        <td>
                          <div className="payment-stack">
                            <span
                              className={`pill ${
                                paiementStatut === 'paye'
                                  ? 'success'
                                  : paiementStatut === 'rembourse'
                                    ? 'danger'
                                    : 'warning'
                              }`}
                            >
                              {paiementLabel}
                            </span>
                            {paiementStatut !== 'paye' && statutCommande !== 'annulee' && (
                              <button
                                className="secondary"
                                onClick={() =>
                                  isManual
                                    ? updateManualPaymentStatus(commandeId, 'paye')
                                    : markPaymentAsPaid(commandeId)
                                }
                                style={{
                                  display: 'inline-flex',
                                  alignItems: 'center',
                                  gap: 6,
                                  padding: '6px 10px',
                                  borderRadius: 999,
                                }}
                              >
                                OK
                              </button>
                            )}
                          </div>
                        </td>
                        <td>
                          <div className="step-actions">
                            <button
                              className="secondary"
                              disabled={!prevSuivi}
                              onClick={() =>
                                prevSuivi &&
                                (isManual ? updateManualSuivi(commandeId, prevSuivi) : updateSuivi(commandeId, prevSuivi))
                              }
                            >
                              Prec
                            </button>
                            <span className="pill muted">{currentSuiviLabel}</span>
                            <button
                              className="secondary"
                              disabled={!nextSuivi}
                              onClick={() =>
                                nextSuivi &&
                                (isManual ? updateManualSuivi(commandeId, nextSuivi) : updateSuivi(commandeId, nextSuivi))
                              }
                            >
                              Suiv
                            </button>
                          </div>
                        </td>
                        <td>
                          <div className="status-select" data-disabled={!canChangeStatutCommande}>
                            <span
                              className={`pill ${
                                statutCommande === 'terminee'
                                  ? 'success'
                                  : statutCommande === 'annulee'
                                    ? 'danger'
                                    : 'warning'
                              }`}
                            >
                              <span className="status-ellipsis">
                                {STATUTS_COMMANDE.find((s) => s.value === statutCommande)?.label || statutCommande}
                              </span>
                              <span className="chevron">v</span>
                            </span>
                            <select
                              className="status-native"
                              value={statutCommande}
                              disabled={!canChangeStatutCommande}
                              onChange={(e) =>
                                isManual
                                  ? updateManualOrderStatus(commandeId, e.target.value)
                                  : updateStatutCommande(commande, e.target.value)
                              }
                            >
                              {STATUTS_COMMANDE.map((statut) => (
                                <option key={statut.value} value={statut.value}>{statut.label}</option>
                              ))}
                            </select>
                          </div>
                        </td>
                        <td>
                          {isManual ? (
                            <span className="pill muted">Non dispo</span>
                          ) : (
                            <button
                              onClick={() => toggleResultat(commande)}
                              style={{
                                padding: '6px 10px',
                                borderRadius: 8,
                                border: '1px solid #e2e2e2',
                                background: '#fff',
                                cursor: 'pointer',
                                fontWeight: 600,
                              }}
                            >
                              Resultat ({photosCount}P/{videosCount}V)
                            </button>
                          )}
                        </td>
                      </tr>
                      {!isManual && openResultatId === commandeId && (
                        <tr>
                          <td colSpan={8}>
                            <div className="panel resultat-panel" style={{ marginTop: 12 }}>
                              {commande.retours?.length ? (
                                <div style={{ marginBottom: 16 }}>
                                  <h4 style={{ marginBottom: 8 }}>Retouches</h4>
                                  <div style={{ display: 'grid', gap: 10 }}>
                                    {commande.retours.map((retour) => (
                                      <div
                                        key={retour._id}
                                        style={{
                                          padding: 10,
                                          border: '1px solid #e7e7e7',
                                          borderRadius: 10,
                                          background: '#fafafa',
                                        }}
                                      >
                                        <div style={{ fontWeight: 600, marginBottom: 4 }}>
                                          {retour.description}
                                        </div>
                                        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                                          <span style={{ fontSize: 12, color: '#666' }}>Statut:</span>
                                          <select
                                            value={retour.statut}
                                            onChange={(e) =>
                                              updateRetourStatus(commande._id, retour._id, e.target.value)
                                            }
                                          >
                                            {RETOUR_STATUTS.map((statut) => (
                                              <option key={statut.value} value={statut.value}>
                                                {statut.label}
                                              </option>
                                            ))}
                                          </select>
                                        </div>
                                      </div>
                                    ))}
                                  </div>
                                </div>
                              ) : null}
                              <div className="result-grid">
                                <div className="result-card">
                                  <div className="result-head">
                                    <h4>Photos</h4>
                                    <label className="upload-btn">
                                      <input
                                        type="file"
                                        accept="image/*"
                                        multiple
                                        onChange={(e) => {
                                          uploadImages(commande._id, e.target.files);
                                          e.target.value = '';
                                        }}
                                      />
                                      {draft.uploadingImages ? 'Upload...' : 'Uploader'}
                                    </label>
                                  </div>
                                  <div className="media-grid">
                                    {photoList.length ? photoList.map((url) => (
                                      <img key={url} src={url} alt="photo resultat" />
                                    )) : <p className="muted-text">Aucune photo</p>}
                                  </div>
                                  <textarea
                                    value={draft.photos || ''}
                                    onChange={(e) => updateDraft(commande._id, 'photos', e.target.value)}
                                    rows={4}
                                    placeholder="Ou collez les URLs (une par ligne)"
                                  />
                                </div>
                                <div className="result-card">
                                  <div className="result-head">
                                    <h4>Videos</h4>
                                    <label className="upload-btn">
                                      <input
                                        type="file"
                                        accept="video/*"
                                        multiple
                                        onChange={(e) => {
                                          uploadVideos(commande._id, e.target.files);
                                          e.target.value = '';
                                        }}
                                      />
                                      {draft.uploadingVideos ? 'Upload...' : 'Uploader'}
                                    </label>
                                  </div>
                                  <div className="media-grid">
                                    {videoList.length ? videoList.map((url) => (
                                      <video key={url} src={url} controls />
                                    )) : <p className="muted-text">Aucune video</p>}
                                  </div>
                                  <textarea
                                    value={draft.videos || ''}
                                    onChange={(e) => updateDraft(commande._id, 'videos', e.target.value)}
                                    rows={4}
                                    placeholder="Ou collez les URLs (une par ligne)"
                                  />
                                </div>
                              </div>
                              {draft.error ? <p className="error-text">{draft.error}</p> : null}
                              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
                                <button
                                  onClick={() => setOpenResultatId(null)}
                                  style={{
                                    padding: '8px 12px',
                                    borderRadius: 8,
                                    border: '1px solid #e2e2e2',
                                    background: '#fff',
                                    cursor: 'pointer',
                                    fontWeight: 600,
                                  }}
                                >
                                  Fermer
                                </button>
                                <button
                                  onClick={() => saveResultat(commande._id)}
                                  disabled={draft.saving || draft.uploadingImages || draft.uploadingVideos}
                                  style={{
                                    padding: '8px 14px',
                                    borderRadius: 8,
                                    border: 'none',
                                    background: '#2b1a0a',
                                    color: '#fff',
                                    cursor: 'pointer',
                                    fontWeight: 600,
                                    opacity: draft.saving ? 0.7 : 1,
                                  }}
                                >
                                  {draft.saving ? 'Enregistrement...' : 'Publier resultat'}
                                </button>
                              </div>
                            </div>
                          </td>
                        </tr>
                      )}
                    </Fragment>
                  );
                })}
              </tbody>
            </table>
          </div>
              ) : (
                <div className="panel table-wrap" style={{ padding: 18 }}>
                  <table className="table modern compact">
                    <thead>
                      <tr>
                        <th>Commande</th>
                        <th>Client</th>
                        <th>Total</th>
                        <th>Livraison</th>
                        <th>Paiement</th>
                        <th>Statut</th>
                      </tr>
                    </thead>
                    <tbody>
                      {filteredManual.map((order) => {
                        const paiementStatutRaw = String(order.statut_paiement || 'en_attente').toLowerCase();
                        const paiementStatut = order.statut_commande === 'annulee' ? 'rembourse' : paiementStatutRaw;
                        const paiementLabel = paiementStatut === 'paye'
                          ? 'Payee'
                          : paiementStatut === 'rembourse'
                            ? 'Remboursee'
                            : paiementStatut === 'echoue'
                              ? 'Echoue'
                              : 'En attente';
                        const canChangeStatutCommande = order.statut_commande !== 'terminee';

                        return (
                          <tr key={order.id}>
                            <td>{order.numero_commande}</td>
                            <td>
                              <span className="cell-ellipsis" title={order.client}>
                                {order.client}
                              </span>
                            </td>
                            <td>{order.montant_total} FCFA</td>
                            <td>
                              <input
                                type="date"
                                value={toDateInputValue(order.date_livraison_estimee)}
                                onChange={(e) => updateManualDeliveryDate(order.id, e.target.value)}
                              />
                            </td>
                            <td>
                              <div className="payment-stack">
                                <span
                                  className={`pill ${
                                    paiementStatut === 'paye'
                                      ? 'success'
                                      : paiementStatut === 'rembourse'
                                        ? 'danger'
                                        : 'warning'
                                  }`}
                                >
                                  {paiementLabel}
                                </span>
                                {paiementStatut !== 'paye' && order.statut_commande !== 'annulee' && (
                                  <button
                                    className="secondary"
                                    onClick={() => updateManualPaymentStatus(order.id, 'paye')}
                                    style={{
                                      display: 'inline-flex',
                                      alignItems: 'center',
                                      gap: 6,
                                      padding: '6px 10px',
                                      borderRadius: 999,
                                    }}
                                  >
                                    OK
                                  </button>
                                )}
                              </div>
                            </td>
                            <td>
                              <div className="status-select" data-disabled={!canChangeStatutCommande}>
                                <span
                                  className={`pill ${
                                    order.statut_commande === 'terminee'
                                      ? 'success'
                                      : order.statut_commande === 'annulee'
                                        ? 'danger'
                                        : 'warning'
                                  }`}
                                >
                                  <span className="status-ellipsis">
                                    {STATUTS_COMMANDE.find((s) => s.value === order.statut_commande)?.label || order.statut_commande}
                                  </span>
                                  <span className="chevron">v</span>
                                </span>
                                <select
                                  className="status-native"
                                  value={order.statut_commande}
                                  disabled={!canChangeStatutCommande}
                                  onChange={(e) => updateManualOrderStatus(order.id, e.target.value)}
                                >
                                  {STATUTS_COMMANDE.map((statut) => (
                                    <option key={statut.value} value={statut.value}>{statut.label}</option>
                                  ))}
                                </select>
                              </div>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </>
          ) : (
            <div className="panel" style={{ padding: 18 }}>
              <p className="muted-text">Choisissez un sous-onglet dans Commandes pour afficher les listes.</p>
            </div>
          )}
        </section>
      </main>
      {showManualModal && (
        <div className="modal-overlay" onClick={closeManualModalForm}>
          <div className="modal-card modal-large" onClick={(e) => e.stopPropagation()}>
            <div className="modal-head">
              <div>
                <h3>
                  Nouvelle commande{' '}
                  {isSurMesureTab ? 'sur mesure' : isTissuTab ? 'tissu' : 'pret a porter'}
                </h3>
                <p className="modal-subtitle">Renseigne les informations principales</p>
              </div>
            </div>

            <div className="modal-body">
              <div className="modal-section">
                <div className="modal-section-title">Client & produit</div>
                <div className="form-grid form-grid-wide">
                  <div className="field-group">
                    <label className="field-label">Client</label>
                    <input
                      value={manualForm.client}
                      onChange={(event) => updateManualField('client', event.target.value)}
                      placeholder="Nom du client"
                    />
                  </div>
                  <div className="field-group">
                    <label className="field-label">{manualItemLabel}</label>
                    <input
                      value={manualForm.article}
                      onChange={(event) => updateManualField('article', event.target.value)}
                      placeholder={isSurMesureTab ? 'Description ou modele' : isTissuTab ? 'Nom du tissu' : 'Nom du produit'}
                    />
                  </div>
                  {isTissuTab ? (
                    <>
                      <div className="field-group">
                        <label className="field-label">Type</label>
                        <select
                          value={manualForm.type_unite}
                          onChange={(event) => updateManualField('type_unite', event.target.value)}
                        >
                          <option value="metre">Mètre</option>
                          <option value="piece">Pièce</option>
                        </select>
                      </div>
                      <div className="field-group">
                        <label className="field-label">Quantité ({manualUnitLabel})</label>
                        <input
                          type="number"
                          value={manualForm.quantite}
                          onChange={(event) => updateManualField('quantite', event.target.value)}
                          placeholder={manualForm.type_unite === 'piece' ? 'Nombre de pièces' : 'Nombre de mètres'}
                        />
                      </div>
                    </>
                  ) : null}
                  {isPretTab ? (
                    <div className="field-group">
                      <label className="field-label">Quantité (pièces)</label>
                      <input
                        type="number"
                        value={manualForm.quantite}
                        onChange={(event) => updateManualField('quantite', event.target.value)}
                        placeholder="Nombre de pièces"
                      />
                    </div>
                  ) : null}
                </div>
              </div>

              <div className="modal-section">
                <div className="modal-section-title">Paiement</div>
                <div className="form-grid form-grid-wide">
                  <div className="field-group">
                    <label className="field-label">Prix total</label>
                    <input
                      type="number"
                      value={manualForm.montant_total}
                      onChange={(event) => updateManualField('montant_total', event.target.value)}
                      placeholder="FCFA"
                    />
                  </div>
                  <div className="field-group">
                    <label className="field-label">Prix fournisseur</label>
                    <input
                      type="number"
                      value={manualForm.prix_fournisseur}
                      onChange={(event) => updateManualField('prix_fournisseur', event.target.value)}
                      placeholder="FCFA"
                    />
                  </div>
                  <div className="field-group">
                    <label className="field-label">Bénéfice</label>
                    <input type="number" value={manualBenefice} readOnly />
                  </div>
                  <div className="field-group">
                    <label className="field-label">Justificatif paiement</label>
                    <div className="upload-row">
                      <label className="upload-btn">
                        <input
                          type="file"
                          accept="image/*"
                          onChange={(event) => {
                            uploadManualJustificatif(event.target.files?.[0]);
                            event.target.value = '';
                          }}
                        />
                        {manualUploading ? 'Upload...' : 'Uploader'}
                      </label>
                      {manualForm.justificatif ? (
                        <a href={manualForm.justificatif} target="_blank" rel="noreferrer">Voir le justificatif</a>
                      ) : (
                        <span className="muted-text">Aucun fichier</span>
                      )}
                    </div>
                  </div>
                </div>
              </div>

              <div className="modal-section">
                <div className="modal-section-title">Dates & statuts</div>
                <div className="form-grid form-grid-wide">
                  <div className="field-group">
                    <label className="field-label">Date commande</label>
                    <input
                      type="date"
                      value={manualForm.date_commande}
                      onChange={(event) => updateManualField('date_commande', event.target.value)}
                    />
                  </div>
                  <div className="field-group">
                    <label className="field-label">Date livraison</label>
                    <input
                      type="date"
                      value={manualForm.date_livraison_estimee}
                      onChange={(event) => updateManualField('date_livraison_estimee', event.target.value)}
                    />
                  </div>
                  <div className="field-group">
                    <label className="field-label">Statut commande</label>
                    <select
                      value={manualForm.statut_commande}
                      onChange={(event) => updateManualField('statut_commande', event.target.value)}
                    >
                      {STATUTS_COMMANDE.map((statut) => (
                        <option key={statut.value} value={statut.value}>{statut.label}</option>
                      ))}
                    </select>
                  </div>
                  <div className="field-group">
                    <label className="field-label">Statut paiement</label>
                    <select
                      value={manualForm.statut_paiement}
                      onChange={(event) => updateManualField('statut_paiement', event.target.value)}
                    >
                      {PAYMENT_STATUSES.map((statut) => (
                        <option key={statut.value} value={statut.value}>{statut.label}</option>
                      ))}
                    </select>
                  </div>
                </div>
              </div>

              <div className="modal-section">
                <div className="modal-section-title">Note</div>
                <div className="form-grid">
                  <div className="field-group" style={{ gridColumn: '1 / -1' }}>
                    <label className="field-label">Note commande</label>
                    <textarea
                      value={manualForm.note}
                      onChange={(event) => updateManualField('note', event.target.value)}
                      placeholder="Note ou informations complémentaires"
                      rows={3}
                    />
                  </div>
                </div>
              </div>
            </div>
            {manualError ? <p className="error-text">{manualError}</p> : null}
            <div className="modal-actions">
              <button className="secondary" onClick={closeManualModalForm}>Annuler</button>
              <button onClick={saveManualOrder}>Enregistrer</button>
            </div>
          </div>
        </div>
      )}
      {detailLoading || detailCommande || detailError ? (
        <div className="modal-overlay" onClick={closeDetails}>
          <div
            className="modal-card"
            onClick={(e) => e.stopPropagation()}
            style={{ maxWidth: 760 }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3>Details commande</h3>
              <button
                type="button"
                className="secondary"
                onClick={closeDetails}
                style={{ padding: '6px 10px' }}
              >
                Fermer
              </button>
            </div>
            {detailLoading ? (
              <p>Chargement...</p>
            ) : detailError ? (
              <p className="error-text">{detailError}</p>
            ) : detailCommande ? (
              <div style={{ display: 'grid', gap: 12 }}>
                <div className="panel" style={{ padding: 12 }}>
                  <div style={{ display: 'grid', gap: 6 }}>
                    <div><strong>Commande:</strong> {detailCommande.numero_commande}</div>
                    <div>
                      <strong>Client:</strong> {detailCommande.id_client?.prenom} {detailCommande.id_client?.nom}
                    </div>
                    <div><strong>Statut:</strong> {detailCommande.statut}</div>
                    <div><strong>Statut paiement:</strong> {detailCommande.statut_paiement}</div>
                    <div><strong>Date commande:</strong> {formatDate(detailCommande.createdAt)}</div>
                    <div><strong>Livraison estimee:</strong> {formatDate(detailCommande.date_livraison_estimee)}</div>
                    <div><strong>Total:</strong> {detailCommande.montant_total} FCFA</div>
                  </div>
                </div>

                <div className="panel" style={{ padding: 12 }}>
                  <h4 style={{ marginTop: 0 }}>Articles</h4>
                  {(detailCommande.items || []).length === 0 ? (
                    <p>Aucun article.</p>
                  ) : (
                    <div style={{ display: 'grid', gap: 10 }}>
                      {detailCommande.items.map((item, idx) => (
                        <div
                          key={item._id || idx}
                          style={{
                            padding: 10,
                            border: '1px solid #e7e7e7',
                            borderRadius: 10,
                            background: '#fafafa',
                          }}
                        >
                          <div style={{ fontWeight: 700 }}>
                            Article {idx + 1} - {item.id_modele?.nom || 'Modele'}
                          </div>
                          <div>Quantite: {item.quantite || item.qte || 1}</div>
                          {Array.isArray(item.tissus) && item.tissus.length > 0 ? (
                            <div style={{ marginTop: 6 }}>
                              <div style={{ fontWeight: 600, marginBottom: 4 }}>Tissus</div>
                              <ul style={{ margin: 0, paddingLeft: 18 }}>
                                {item.tissus.map((tissu, tIndex) => (
                                  <li key={tIndex}>
                                    {tissu.id_tissu?.nom || 'Tissu'} - {tissu.metrage || tissu.quantite || 0} m
                                  </li>
                                ))}
                              </ul>
                            </div>
                          ) : null}
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            ) : null}
          </div>
        </div>
      ) : null}
    </RequireAdmin>
  );
}








