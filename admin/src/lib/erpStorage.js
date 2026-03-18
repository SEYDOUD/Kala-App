const FINANCE_STORAGE_KEY = 'kala_erp_finance';
const OPS_STORAGE_KEY = 'kala_erp_operations';
const ORDERS_STORAGE_KEY = 'kala_erp_orders';

function toDateString(date) {
  return date.toISOString().slice(0, 10);
}

function addDays(base, offset) {
  const date = new Date(base);
  date.setDate(date.getDate() + offset);
  return date;
}

function createSeedFinance() {
  const today = new Date();
  return {
    caisseInitiale: 250000,
    entries: [
      {
        id: 'ent-1',
        type: 'tissu',
        label: 'Vente tissu bazin',
        montant: 45000,
        date: toDateString(addDays(today, -2)),
        payeur: 'Client Instagram',
        mode: 'orange_money',
        statut: 'paye',
        justificatif: '',
      },
      {
        id: 'ent-2',
        type: 'pret_a_porter',
        label: 'Vente pret a porter',
        montant: 62000,
        date: toDateString(addDays(today, -1)),
        payeur: 'Boutique WhatsApp',
        mode: 'wave',
        statut: 'paye',
        justificatif: '',
      },
      {
        id: 'ent-3',
        type: 'tissu',
        label: 'Vente metrage coton',
        montant: 28000,
        date: toDateString(today),
        payeur: 'Client Facebook',
        mode: 'especes',
        statut: 'en_attente',
        justificatif: '',
      },
    ],
    expenses: [
      {
        id: 'exp-1',
        type: 'fournisseur',
        label: 'Paiement fournisseur bazin',
        montant: 30000,
        date: toDateString(addDays(today, -1)),
        beneficiaire: 'Fournisseur A',
        mode: 'virement',
        statut: 'paye',
        justificatif: '',
      },
      {
        id: 'exp-2',
        type: 'marketing',
        label: 'Campagne Instagram',
        montant: 20000,
        date: toDateString(today),
        beneficiaire: 'Meta Ads',
        mode: 'carte',
        statut: 'a_payer',
        justificatif: '',
      },
    ],
  };
}

function createSeedOperations() {
  const today = new Date();
  return {
    tasks: [
      {
        id: 'task-1',
        title: 'Valider patron Bambara',
        statut: 'a_faire',
        dueDate: toDateString(today),
        owner: 'Atelier',
        priority: 'haute',
      },
      {
        id: 'task-2',
        title: 'Lister tissus tendance',
        statut: 'en_cours',
        dueDate: toDateString(addDays(today, 1)),
        owner: 'Equipe com',
        priority: 'moyenne',
      },
      {
        id: 'task-3',
        title: 'Verifier stock sur mesure',
        statut: 'fait',
        dueDate: toDateString(addDays(today, -1)),
        owner: 'Gestion',
        priority: 'basse',
      },
    ],
    campaigns: [
      {
        id: 'camp-1',
        name: 'Lancement bazin premium',
        canal: 'Instagram',
        budget: 120000,
        statut: 'active',
        startDate: toDateString(addDays(today, -2)),
        endDate: toDateString(addDays(today, 5)),
        objectif: 'Vente metrage',
      },
      {
        id: 'camp-2',
        name: 'Pret a porter weekend',
        canal: 'WhatsApp',
        budget: 45000,
        statut: 'planifiee',
        startDate: toDateString(addDays(today, 3)),
        endDate: toDateString(addDays(today, 8)),
        objectif: 'Conversion',
      },
    ],
  };
}

function createSeedOrders() {
  const today = new Date();
  return {
    sur_mesure: [],
    tissus: [
      {
        id: 'tis-1',
        numero_commande: 'TIS-2603-01',
        article: 'Bazin premium',
        type_unite: 'metre',
        quantite: 6,
        client: 'Client Facebook',
        montant_total: 48000,
        prix_fournisseur: 32000,
        benefice: 16000,
        justificatif: '',
        date_commande: toDateString(addDays(today, -1)),
        date_livraison_estimee: '',
        statut_commande: 'en_cours',
        statut_paiement: 'paye',
        note: '',
        mode_paiement: 'orange_money',
        category: 'tissus',
      },
    ],
    pret_a_porter: [
      {
        id: 'pap-1',
        numero_commande: 'PAP-2603-01',
        article: 'Ensemble week-end',
        type_unite: 'piece',
        quantite: 2,
        client: 'Client Boutique',
        montant_total: 65000,
        prix_fournisseur: 42000,
        benefice: 23000,
        justificatif: '',
        date_commande: toDateString(addDays(today, -2)),
        date_livraison_estimee: toDateString(addDays(today, 4)),
        statut_commande: 'en_attente',
        statut_paiement: 'en_attente',
        note: '',
        mode_paiement: 'especes',
        category: 'pret_a_porter',
      },
    ],
  };
}

function safeParse(value) {
  if (!value) return null;
  try {
    return JSON.parse(value);
  } catch (error) {
    return null;
  }
}

function loadStoredData(key, createFallback) {
  if (typeof window === 'undefined') {
    return createFallback();
  }
  const raw = window.localStorage.getItem(key);
  const parsed = safeParse(raw);
  if (!parsed) {
    return createFallback();
  }
  return parsed;
}

function saveStoredData(key, value) {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(key, JSON.stringify(value));
}

export {
  FINANCE_STORAGE_KEY,
  OPS_STORAGE_KEY,
  ORDERS_STORAGE_KEY,
  createSeedFinance,
  createSeedOperations,
  createSeedOrders,
  loadStoredData,
  saveStoredData,
};
