'use client';

import { useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import NavBar from '@/components/NavBar';
import RequireAdmin from '@/components/RequireAdmin';
import { apiRequest } from '@/lib/api';
import {
  FINANCE_STORAGE_KEY,
  createSeedFinance,
  loadStoredData,
  saveStoredData,
} from '@/lib/erpStorage';

const ENTRY_TYPES = [
  { value: 'sur_mesure', label: 'Sur mesure' },
  { value: 'tissu', label: 'Vente tissu' },
  { value: 'pret_a_porter', label: 'Pret a porter' },
  { value: 'autre', label: 'Autre entree' },
];

const EXPENSE_TYPES = [
  { value: 'fournisseur', label: 'Fournisseur' },
  { value: 'marketing', label: 'Marketing' },
  { value: 'logistique', label: 'Logistique' },
  { value: 'salaire', label: 'Salaire' },
  { value: 'autre', label: 'Autre sortie' },
];

const PAYMENT_MODES = [
  { value: 'wave', label: 'Wave' },
  { value: 'orange_money', label: 'Orange Money' },
  { value: 'virement', label: 'Virement' },
  { value: 'especes', label: 'Especes' },
  { value: 'carte', label: 'Carte' },
];

const TRANSACTION_FILTERS = [
  { value: 'all', label: 'Tous' },
  { value: 'sur_mesure', label: 'Sur mesure' },
  { value: 'tissu', label: 'Vente tissu' },
  { value: 'pret_a_porter', label: 'Pret a porter' },
  { value: 'autre_entree', label: 'Entrees manuelles' },
  { value: 'sorties', label: 'Sorties' },
];

function toNumber(value) {
  const amount = Number(value);
  return Number.isFinite(amount) ? amount : 0;
}

function formatAmount(value) {
  return new Intl.NumberFormat('fr-FR').format(value || 0);
}

function todayString() {
  return new Date().toISOString().slice(0, 10);
}

function buildDefaultEntryForm() {
  return {
    type: 'tissu',
    label: '',
    montant: '',
    date: todayString(),
    payeur: '',
    mode: 'wave',
    statut: 'paye',
    justificatif: '',
  };
}

function buildDefaultExpenseForm() {
  return {
    type: 'fournisseur',
    label: '',
    montant: '',
    date: todayString(),
    beneficiaire: '',
    mode: 'virement',
    statut: 'a_payer',
    justificatif: '',
  };
}

function getStatusPill(status) {
  if (status === 'paye') return 'pill success';
  if (status === 'rembourse' || status === 'echoue') return 'pill danger';
  if (status === 'a_payer') return 'pill danger';
  return 'pill warning';
}

export default function FinancesPage() {
  const searchParams = useSearchParams();
  const tabParam = searchParams.get('tab');
  const [finance, setFinance] = useState(createSeedFinance());
  const [commandes, setCommandes] = useState([]);
  const [showTransactionModal, setShowTransactionModal] = useState(false);
  const [transactionType, setTransactionType] = useState('entree');
  const [transactionForm, setTransactionForm] = useState(buildDefaultEntryForm());
  const [transactionFilter, setTransactionFilter] = useState('all');
  const [activeTab, setActiveTab] = useState('transactions');
  const [error, setError] = useState('');

  const dateText = useMemo(
    () => new Date().toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }),
    []
  );

  useEffect(() => {
    setFinance(loadStoredData(FINANCE_STORAGE_KEY, createSeedFinance));
  }, []);

  useEffect(() => {
    if (tabParam === 'fournisseurs') {
      setActiveTab('fournisseurs');
      return;
    }
    setActiveTab('transactions');
  }, [tabParam]);

  useEffect(() => {
    saveStoredData(FINANCE_STORAGE_KEY, finance);
  }, [finance]);

  useEffect(() => {
    async function loadCommandes() {
      try {
        const data = await apiRequest('/api/commandes');
        setCommandes(data.commandes || []);
      } catch {
        setCommandes([]);
      }
    }

    loadCommandes();
  }, []);

  const supplierSuggestions = commandes
    .filter((commande) => ['confirmee', 'en_cours', 'prete', 'terminee', 'livree'].includes((commande?.statut || '').toLowerCase()))
    .map((commande) => {
      const montant = (commande.items || []).reduce((sum, item) => {
        const totalTissus = (item.tissus || []).reduce((acc, tissu) => acc + toNumber(tissu.sous_total), 0);
        return sum + totalTissus;
      }, 0);
      return {
        id: commande._id,
        numero: commande.numero_commande,
        montant,
      };
    })
    .filter((item) => item.montant > 0)
    .slice(0, 5);

  const entrySourceLabel = (entry) => {
    if (entry.source === 'sur_mesure') return 'Commande';
    if (entry.source === 'tissus' || entry.source === 'pret_a_porter') return 'Commande manuelle';
    return entry.source || 'Manuel';
  };

  const transactions = useMemo(() => {
    const entreeList = finance.entries.map((entry) => ({
      id: entry.id,
      kind: 'entree',
      subType: entry.type,
      label: entry.label,
      date: entry.date,
      amount: entry.montant,
      counterparty: entry.payeur,
      mode: entry.mode,
      statut: entry.statut,
      source: entrySourceLabel(entry),
    }));

    const sortieList = finance.expenses.map((expense) => ({
      id: expense.id,
      kind: 'sortie',
      subType: expense.type,
      label: expense.label,
      date: expense.date,
      amount: expense.montant,
      counterparty: expense.beneficiaire,
      mode: expense.mode,
      statut: expense.statut,
      source: 'Manuel',
    }));

    return [...entreeList, ...sortieList].sort((a, b) => {
      const dateA = new Date(a.date || 0).getTime();
      const dateB = new Date(b.date || 0).getTime();
      return dateB - dateA;
    });
  }, [finance.entries, finance.expenses]);

  const filteredTransactions = transactions.filter((transaction) => {
    switch (transactionFilter) {
      case 'sur_mesure':
        return transaction.kind === 'entree' && transaction.subType === 'sur_mesure';
      case 'tissu':
        return transaction.kind === 'entree' && transaction.subType === 'tissu';
      case 'pret_a_porter':
        return transaction.kind === 'entree' && transaction.subType === 'pret_a_porter';
      case 'autre_entree':
        return transaction.kind === 'entree' && transaction.subType === 'autre';
      case 'sorties':
        return transaction.kind === 'sortie';
      default:
        return true;
    }
  });

  const addEntry = (form) => {
    if (!form.label || !form.montant) {
      setError('Renseigne un libelle et un montant pour l entree.');
      return false;
    }
    const newEntry = { ...form, id: `ent-${Date.now()}`, montant: toNumber(form.montant) };
    setFinance((prev) => ({ ...prev, entries: [newEntry, ...prev.entries] }));
    setError('');
    return true;
  };

  const addExpense = (form) => {
    if (!form.label || !form.montant) {
      setError('Renseigne un libelle et un montant pour la sortie.');
      return false;
    }
    const newExpense = { ...form, id: `exp-${Date.now()}`, montant: toNumber(form.montant) };
    setFinance((prev) => ({ ...prev, expenses: [newExpense, ...prev.expenses] }));
    setError('');
    return true;
  };

  const openTransactionModal = () => {
    setTransactionType('entree');
    setTransactionForm(buildDefaultEntryForm());
    setShowTransactionModal(true);
    setError('');
  };

  const updateTransactionType = (value) => {
    setTransactionType(value);
    setTransactionForm(value === 'entree' ? buildDefaultEntryForm() : buildDefaultExpenseForm());
  };

  const updateTransactionField = (field, value) => {
    setTransactionForm((prev) => ({ ...prev, [field]: value }));
  };

  const submitTransaction = () => {
    const success =
      transactionType === 'entree'
        ? addEntry(transactionForm)
        : addExpense(transactionForm);
    if (success) {
      setShowTransactionModal(false);
    }
  };

  const markExpenseStatus = (id, statut) => {
    setFinance((prev) => ({
      ...prev,
      expenses: prev.expenses.map((expense) => (expense.id === id ? { ...expense, statut } : expense)),
    }));
  };

  const addSupplierExpense = (suggestion) => {
    const newExpense = {
      id: `exp-${Date.now()}`,
      type: 'fournisseur',
      label: `Paiement fournisseur ${suggestion.numero}`,
      montant: suggestion.montant,
      date: todayString(),
      beneficiaire: 'Fournisseur',
      mode: 'virement',
      statut: 'a_payer',
      justificatif: '',
    };
    setFinance((prev) => ({ ...prev, expenses: [newExpense, ...prev.expenses] }));
  };

  return (
    <RequireAdmin>
      <main className="admin-shell">
        <NavBar />

        <section className="main">
          <div className="topline">
            <span className="breadcrumb">Finances</span>
            <span className="date-text">{dateText}</span>
          </div>

          <h1 className="page-title">Tableau de bord financier</h1>
          <p className="subtitle">Suivi des ventes tissus, sur mesure, pret a porter et sorties.</p>

          {error && <p className="error-text">{error}</p>}

          {activeTab === 'transactions' ? (
            <>
              <div className="transaction-toolbar">
                <button onClick={openTransactionModal}>Ajouter une transaction</button>
                <p className="muted-text">Enregistre une entree ou une sortie manuelle.</p>
              </div>

              <div className="section-stack">
                <section className="section-card">
                  <div className="section-head">
                    <div>
                      <h3>Transactions</h3>
                      <p>Filtrer par type de vente ou sortie</p>
                    </div>
                  </div>
                  <div className="filter-tabs">
                    {TRANSACTION_FILTERS.map((filter) => (
                      <button
                        key={filter.value}
                        className={`filter-btn ${transactionFilter === filter.value ? 'active' : ''}`}
                        onClick={() => setTransactionFilter(filter.value)}
                      >
                        {filter.label}
                      </button>
                    ))}
                  </div>
                  <div className="table-wrap">
                    <table className="table modern compact">
                      <thead>
                        <tr>
                          <th>Date</th>
                          <th>Type</th>
                          <th>Source</th>
                          <th>Libelle</th>
                          <th>Montant</th>
                          <th>Statut</th>
                          <th>Contrepartie</th>
                          <th>Mode</th>
                        </tr>
                      </thead>
                      <tbody>
                        {filteredTransactions.length === 0 ? (
                          <tr>
                            <td colSpan="8" className="muted-text">Aucune transaction pour ce filtre.</td>
                          </tr>
                        ) : (
                          filteredTransactions.map((transaction) => (
                            <tr key={transaction.id}>
                              <td>{transaction.date || '-'}</td>
                              <td>
                                {transaction.kind === 'sortie'
                                  ? 'Sortie'
                                  : ENTRY_TYPES.find((type) => type.value === transaction.subType)?.label || 'Entree'}
                              </td>
                              <td>{transaction.source}</td>
                              <td><span className="cell-ellipsis">{transaction.label}</span></td>
                              <td>{formatAmount(transaction.amount)} FCFA</td>
                              <td><span className={getStatusPill(transaction.statut)}>{transaction.statut || '-'}</span></td>
                              <td><span className="cell-ellipsis">{transaction.counterparty || '-'}</span></td>
                              <td>{PAYMENT_MODES.find((mode) => mode.value === transaction.mode)?.label || transaction.mode || '-'}</td>
                            </tr>
                          ))
                        )}
                      </tbody>
                    </table>
                  </div>
                </section>

              </div>
            </>
          ) : (
            <div className="section-stack">
              <section className="section-card">
                <div className="section-head">
                  <div>
                    <h3>Sorties fournisseurs</h3>
                    <p>Suivi des paiements en attente</p>
                  </div>
                </div>
                <div className="table-wrap">
                  <table className="table modern compact">
                    <thead>
                      <tr>
                        <th>Date</th>
                        <th>Libelle</th>
                        <th>Montant</th>
                        <th>Beneficiaire</th>
                        <th>Mode</th>
                        <th>Statut</th>
                        <th>Justificatif</th>
                      </tr>
                    </thead>
                    <tbody>
                      {finance.expenses
                        .filter((expense) => expense.type === 'fournisseur')
                        .map((expense) => (
                          <tr key={expense.id}>
                            <td>{expense.date}</td>
                            <td><span className="cell-ellipsis">{expense.label}</span></td>
                            <td>{formatAmount(expense.montant)} FCFA</td>
                            <td><span className="cell-ellipsis">{expense.beneficiaire || '-'}</span></td>
                            <td>{PAYMENT_MODES.find((mode) => mode.value === expense.mode)?.label || expense.mode}</td>
                            <td>
                              <button className={getStatusPill(expense.statut)} onClick={() => markExpenseStatus(expense.id, expense.statut === 'paye' ? 'a_payer' : 'paye')}>
                                {expense.statut.replace('_', ' ')}
                              </button>
                            </td>
                            <td>{expense.justificatif ? <a href={expense.justificatif} target="_blank" rel="noreferrer">Ouvrir</a> : '-'}</td>
                          </tr>
                        ))}
                    </tbody>
                  </table>
                </div>
              </section>

              <section className="section-card">
                <div className="section-head">
                  <div>
                    <h3>Paiements fournisseurs suggeres</h3>
                    <p>Base sur les commandes valides</p>
                  </div>
                </div>
                <div className="list-stack">
                  {supplierSuggestions.map((suggestion) => (
                    <div key={suggestion.id} className="list-item">
                      <div>
                        <h4>{suggestion.numero}</h4>
                        <p>Montant tissus estime</p>
                      </div>
                      <div className="list-actions">
                        <span className="pill warning">{formatAmount(suggestion.montant)} FCFA</span>
                        <button className="secondary" onClick={() => addSupplierExpense(suggestion)}>Ajouter en sortie</button>
                      </div>
                    </div>
                  ))}
                  {supplierSuggestions.length === 0 && (
                    <p className="muted-text">Aucune suggestion disponible.</p>
                  )}
                </div>
              </section>
            </div>
          )}

          {showTransactionModal && (
            <div className="modal-overlay" onClick={() => setShowTransactionModal(false)}>
              <div className="modal-card modal-large" onClick={(event) => event.stopPropagation()}>
                <div className="modal-head">
                  <div>
                    <h3>Nouvelle transaction</h3>
                    <p className="modal-subtitle">Choisir entree ou sortie et renseigner les infos</p>
                  </div>
                </div>

                <div className="modal-body">
                  <div className="modal-section">
                    <div className="modal-section-title">Type & categorie</div>
                    <div className="form-grid form-grid-wide">
                      <div className="field-group">
                        <label className="field-label">Type de transaction</label>
                        <select value={transactionType} onChange={(event) => updateTransactionType(event.target.value)}>
                          <option value="entree">Entree</option>
                          <option value="sortie">Sortie</option>
                        </select>
                      </div>
                      <div className="field-group">
                        <label className="field-label">Categorie</label>
                        <select
                          value={transactionForm.type}
                          onChange={(event) => updateTransactionField('type', event.target.value)}
                        >
                          {(transactionType === 'entree' ? ENTRY_TYPES : EXPENSE_TYPES).map((type) => (
                            <option key={type.value} value={type.value}>{type.label}</option>
                          ))}
                        </select>
                      </div>
                      <div className="field-group">
                        <label className="field-label">Libelle</label>
                        <input
                          value={transactionForm.label}
                          onChange={(event) => updateTransactionField('label', event.target.value)}
                          placeholder="Ex: Vente tissus"
                        />
                      </div>
                      <div className="field-group">
                        <label className="field-label">Montant</label>
                        <input
                          type="number"
                          value={transactionForm.montant}
                          onChange={(event) => updateTransactionField('montant', event.target.value)}
                        />
                      </div>
                    </div>
                  </div>

                  <div className="modal-section">
                    <div className="modal-section-title">Details</div>
                    <div className="form-grid form-grid-wide">
                      <div className="field-group">
                        <label className="field-label">Date</label>
                        <input
                          type="date"
                          value={transactionForm.date}
                          onChange={(event) => updateTransactionField('date', event.target.value)}
                        />
                      </div>
                      {transactionType === 'entree' ? (
                        <div className="field-group">
                          <label className="field-label">Payeur</label>
                          <input
                            value={transactionForm.payeur || ''}
                            onChange={(event) => updateTransactionField('payeur', event.target.value)}
                          />
                        </div>
                      ) : (
                        <div className="field-group">
                          <label className="field-label">Beneficiaire</label>
                          <input
                            value={transactionForm.beneficiaire || ''}
                            onChange={(event) => updateTransactionField('beneficiaire', event.target.value)}
                          />
                        </div>
                      )}
                      <div className="field-group">
                        <label className="field-label">Mode de paiement</label>
                        <select
                          value={transactionForm.mode}
                          onChange={(event) => updateTransactionField('mode', event.target.value)}
                        >
                          {PAYMENT_MODES.map((mode) => (
                            <option key={mode.value} value={mode.value}>{mode.label}</option>
                          ))}
                        </select>
                      </div>
                      <div className="field-group">
                        <label className="field-label">Statut</label>
                        <select
                          value={transactionForm.statut}
                          onChange={(event) => updateTransactionField('statut', event.target.value)}
                        >
                          {transactionType === 'entree' ? (
                            <>
                              <option value="paye">Paye</option>
                              <option value="en_attente">En attente</option>
                            </>
                          ) : (
                            <>
                              <option value="a_payer">A payer</option>
                              <option value="paye">Paye</option>
                            </>
                          )}
                        </select>
                      </div>
                      <div className="field-group">
                        <label className="field-label">Justificatif (lien)</label>
                        <input
                          value={transactionForm.justificatif || ''}
                          onChange={(event) => updateTransactionField('justificatif', event.target.value)}
                          placeholder="https://..."
                        />
                      </div>
                    </div>
                  </div>
                </div>

                <div className="modal-actions">
                  <button className="secondary" onClick={() => setShowTransactionModal(false)}>Annuler</button>
                  <button onClick={submitTransaction}>Enregistrer</button>
                </div>
              </div>
            </div>
          )}
        </section>
      </main>
    </RequireAdmin>
  );
}
