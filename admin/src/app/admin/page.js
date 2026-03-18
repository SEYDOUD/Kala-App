'use client';

import { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import NavBar from '@/components/NavBar';
import RequireAdmin from '@/components/RequireAdmin';
import { apiRequest } from '@/lib/api';
import {
  FINANCE_STORAGE_KEY,
  OPS_STORAGE_KEY,
  createSeedFinance,
  createSeedOperations,
  loadStoredData,
  saveStoredData,
} from '@/lib/erpStorage';

const DAY_RANGE = 10;

const kpiIcons = {
  total: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <rect x="4" y="11" width="4" height="9" rx="1" fill="currentColor" />
      <rect x="10" y="7" width="4" height="13" rx="1" fill="currentColor" />
      <rect x="16" y="4" width="4" height="16" rx="1" fill="currentColor" />
    </svg>
  ),
  tissu: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <rect x="4" y="5" width="16" height="14" rx="2" fill="currentColor" />
      <path d="M4 10h16M4 14h16" stroke="#fff" strokeWidth="2" />
    </svg>
  ),
  pret: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M6 6l6 4 6-4" stroke="currentColor" strokeWidth="2" fill="none" strokeLinecap="round" />
      <path d="M12 10v8" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
      <path d="M6 20h12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
    </svg>
  ),
  sur: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M6 18l12-12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
      <circle cx="7" cy="17" r="3" fill="currentColor" />
      <circle cx="17" cy="7" r="3" fill="currentColor" />
    </svg>
  ),
  sorties: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M12 4v12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
      <path d="M6 12l6 6 6-6" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
      <rect x="4" y="19" width="16" height="2" rx="1" fill="currentColor" />
    </svg>
  ),
  caisse: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <rect x="3" y="7" width="18" height="10" rx="3" fill="currentColor" />
      <circle cx="16.5" cy="12" r="2.5" fill="#fff" />
      <rect x="6" y="10" width="5" height="2" rx="1" fill="#fff" />
    </svg>
  ),
};

function startOfDay(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

function toNumber(value) {
  const amount = Number(value);
  return Number.isFinite(amount) ? amount : 0;
}

function formatAmount(value) {
  return new Intl.NumberFormat('fr-FR').format(value || 0);
}

function formatCompact(value) {
  return new Intl.NumberFormat('fr-FR', {
    notation: 'compact',
    maximumFractionDigits: 1,
  }).format(value || 0);
}

function normalizeStatutCommande(commande) {
  const raw = (commande?.statut_commande || '').toLowerCase();
  if (raw) return raw;
  const step = (commande?.statut || '').toLowerCase();
  if (['livree', 'terminee', 'termine'].includes(step)) return 'terminee';
  if (step === 'annulee') return 'annulee';
  if (step === 'en_attente') return 'en_attente';
  return 'en_cours';
}

function buildDailySeries({ commandes, entries, expenses, dayRange = DAY_RANGE }) {
  const today = startOfDay(new Date());
  const dayMap = new Map();

  for (let index = dayRange - 1; index >= 0; index -= 1) {
    const date = new Date(today);
    date.setDate(today.getDate() - index);
    const key = date.toISOString().slice(0, 10);

    dayMap.set(key, {
      key,
      shortLabel: date.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit' }),
      revenue: 0,
      cash: 0,
    });
  }

  commandes.forEach((commande) => {
    if (!commande?.createdAt) return;
    if ((commande?.statut_paiement || '').toLowerCase() !== 'paye') return;

    const createdAt = new Date(commande.createdAt);
    if (Number.isNaN(createdAt.getTime())) return;

    const key = startOfDay(createdAt).toISOString().slice(0, 10);
    const day = dayMap.get(key);
    if (!day) return;

    const amount = toNumber(commande.montant_total);
    day.revenue += amount;
    day.cash += amount;
  });

  entries.forEach((entry) => {
    if ((entry?.statut || '').toLowerCase() !== 'paye') return;
    const date = new Date(entry.date);
    if (Number.isNaN(date.getTime())) return;
    const key = startOfDay(date).toISOString().slice(0, 10);
    const day = dayMap.get(key);
    if (!day) return;

    const amount = toNumber(entry.montant);
    day.revenue += amount;
    day.cash += amount;
  });

  expenses.forEach((expense) => {
    if ((expense?.statut || '').toLowerCase() !== 'paye') return;
    const date = new Date(expense.date);
    if (Number.isNaN(date.getTime())) return;
    const key = startOfDay(date).toISOString().slice(0, 10);
    const day = dayMap.get(key);
    if (!day) return;

    const amount = toNumber(expense.montant);
    day.cash -= amount;
  });

  return Array.from(dayMap.values());
}

function LineChart({ data, dataKey, title, color, yFormatter = (value) => value }) {
  const width = 640;
  const height = 220;
  const ticksCount = 4;
  const padding = { top: 18, right: 18, bottom: 30, left: 56 };
  const availableWidth = width - padding.left - padding.right;
  const availableHeight = height - padding.top - padding.bottom;

  const values = data.map((item) => item[dataKey]);
  const maxValue = Math.max(...values, 1);

  const points = data.map((item, index) => {
    const x = padding.left + (index * availableWidth) / Math.max(data.length - 1, 1);
    const y = padding.top + availableHeight - (item[dataKey] / maxValue) * availableHeight;
    return { x, y, label: item.shortLabel, value: item[dataKey] };
  });

  const yTicks = Array.from({ length: ticksCount + 1 }, (_, index) => {
    const ratio = index / ticksCount;
    const value = Math.round(maxValue * (1 - ratio));
    return {
      value,
      y: padding.top + availableHeight * ratio,
    };
  });

  const path = points
    .map((point, index) => `${index === 0 ? 'M' : 'L'} ${point.x.toFixed(1)} ${point.y.toFixed(1)}`)
    .join(' ');

  return (
    <section className="chart-card">
      <div className="chart-head">
        <h3>{title}</h3>
        <span>{data.length} derniers jours</span>
      </div>

      <svg viewBox={`0 0 ${width} ${height}`} role="img" aria-label={title}>
        {yTicks.map((tick) => (
          <g key={`${title}-${tick.y}`}>
            <line x1={padding.left} y1={tick.y} x2={width - padding.right} y2={tick.y} className="chart-grid-line" />
            <text x={padding.left - 8} y={tick.y + 4} textAnchor="end" className="chart-y-label">
              {yFormatter(tick.value)}
            </text>
          </g>
        ))}

        <line x1={padding.left} y1={padding.top} x2={padding.left} y2={height - padding.bottom} className="chart-axis-line" />
        <line x1={padding.left} y1={height - padding.bottom} x2={width - padding.right} y2={height - padding.bottom} className="chart-axis-line" />

        <path d={path} fill="none" stroke={color} strokeWidth="3" strokeLinejoin="round" strokeLinecap="round" />

        {points.map((point) => (
          <g key={`${title}-${point.label}`}>
            <circle cx={point.x} cy={point.y} r="4" fill={color} />
            <text x={point.x} y={height - 10} textAnchor="middle" className="chart-x-label">
              {point.label}
            </text>
          </g>
        ))}
      </svg>
    </section>
  );
}

function BarChart({ data, title, color }) {
  const width = 520;
  const height = 220;
  const padding = { top: 18, right: 20, bottom: 50, left: 40 };
  const availableWidth = width - padding.left - padding.right;
  const availableHeight = height - padding.top - padding.bottom;
  const maxValue = Math.max(...data.map((item) => item.value), 1);
  const barGap = 12;
  const barWidth = data.length
    ? (availableWidth - barGap * (data.length - 1)) / data.length
    : availableWidth;

  const ticksCount = 4;
  const yTicks = Array.from({ length: ticksCount + 1 }, (_, index) => {
    const ratio = index / ticksCount;
    const value = Math.round(maxValue * (1 - ratio));
    return {
      value,
      y: padding.top + availableHeight * ratio,
    };
  });

  return (
    <section className="chart-card">
      <div className="chart-head">
        <h3>{title}</h3>
        <span>{data.length} produits</span>
      </div>
      {data.length === 0 ? (
        <p className="muted-text">Aucune donnee pour le moment.</p>
      ) : (
        <svg viewBox={`0 0 ${width} ${height}`} role="img" aria-label={title} className="bar-chart">
          {yTicks.map((tick) => (
            <g key={`${title}-${tick.y}`}>
              <line x1={padding.left} y1={tick.y} x2={width - padding.right} y2={tick.y} className="chart-grid-line" />
              <text x={padding.left - 8} y={tick.y + 4} textAnchor="end" className="chart-y-label">
                {formatCompact(tick.value)}
              </text>
            </g>
          ))}
          <line x1={padding.left} y1={padding.top} x2={padding.left} y2={height - padding.bottom} className="chart-axis-line" />
          <line x1={padding.left} y1={height - padding.bottom} x2={width - padding.right} y2={height - padding.bottom} className="chart-axis-line" />

          {data.map((item, index) => {
            const barHeight = (item.value / maxValue) * availableHeight;
            const x = padding.left + index * (barWidth + barGap);
            const y = padding.top + (availableHeight - barHeight);
            const shortLabel = item.label.length > 8 ? `${item.label.slice(0, 8)}...` : item.label;
            return (
              <g key={`${item.label}-${index}`}>
                <rect x={x} y={y} width={barWidth} height={barHeight} rx="6" fill={color} />
                <text x={x + barWidth / 2} y={height - 20} textAnchor="middle" className="chart-x-label">
                  {shortLabel}
                </text>
              </g>
            );
          })}
        </svg>
      )}
    </section>
  );
}

export default function DashboardPage() {
  const [commandes, setCommandes] = useState([]);
  const [finance, setFinance] = useState(createSeedFinance());
  const [operations, setOperations] = useState(createSeedOperations());

  const dateText = useMemo(
    () => new Date().toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }),
    []
  );

  useEffect(() => {
    setFinance(loadStoredData(FINANCE_STORAGE_KEY, createSeedFinance));
    setOperations(loadStoredData(OPS_STORAGE_KEY, createSeedOperations));
  }, []);

  useEffect(() => {
    saveStoredData(FINANCE_STORAGE_KEY, finance);
  }, [finance]);

  useEffect(() => {
    saveStoredData(OPS_STORAGE_KEY, operations);
  }, [operations]);

  useEffect(() => {
    async function load() {
      try {
        const commandesData = await apiRequest('/api/commandes');
        setCommandes(commandesData.commandes || []);
      } catch {
        setCommandes([]);
      }
    }

    load();
  }, []);

  const dailySeries = useMemo(
    () => buildDailySeries({ commandes, entries: finance.entries, expenses: finance.expenses }),
    [commandes, finance.entries, finance.expenses]
  );

  const surMesureRevenue = finance.entries
    .filter((entry) => entry.type === 'sur_mesure')
    .reduce((sum, entry) => sum + toNumber(entry.montant), 0);

  const tissuRevenue = finance.entries
    .filter((entry) => entry.type === 'tissu')
    .reduce((sum, entry) => sum + toNumber(entry.montant), 0);

  const pretRevenue = finance.entries
    .filter((entry) => entry.type === 'pret_a_porter')
    .reduce((sum, entry) => sum + toNumber(entry.montant), 0);

  const autresRevenue = finance.entries
    .filter((entry) => entry.type === 'autre')
    .reduce((sum, entry) => sum + toNumber(entry.montant), 0);

  const totalExpenses = finance.expenses.reduce((sum, entry) => sum + toNumber(entry.montant), 0);
  const totalRevenue = surMesureRevenue + tissuRevenue + pretRevenue + autresRevenue;
  const caisse = toNumber(finance.caisseInitiale) + totalRevenue - totalExpenses;

  const commandesCounts = commandes.reduce(
    (acc, commande) => {
      const key = normalizeStatutCommande(commande);
      acc[key] = (acc[key] || 0) + 1;
      return acc;
    },
    { en_attente: 0, en_cours: 0, terminee: 0, annulee: 0 }
  );

  const tasks = operations.tasks || [];
  const campaigns = operations.campaigns || [];

  const tasksEnCours = tasks.filter((task) => task.statut === 'en_cours').length;
  const tasksEnAttente = tasks.filter((task) => task.statut === 'a_faire').length;
  const campagnesActives = campaigns.filter((campaign) => campaign.statut === 'active').length;

  const segments = [
    { label: 'Sur mesure', value: surMesureRevenue, color: '#2b1a0a' },
    { label: 'Tissus', value: tissuRevenue, color: '#d89a08' },
    { label: 'Pret a porter', value: pretRevenue, color: '#f4b400' },
    { label: 'Autres', value: autresRevenue, color: '#8a704f' },
  ];

  const totalSegments = segments.reduce((sum, seg) => sum + seg.value, 0) || 1;

  const { topModeles, topTissus } = useMemo(() => {
    const modeleMap = new Map();
    const tissuMap = new Map();

    const addToMap = (map, id, nom, type, montant) => {
      if (!id) return;
      const current = map.get(id) || { id, nom, type, montant: 0 };
      map.set(id, {
        id,
        nom: nom || current.nom,
        type: type || current.type,
        montant: current.montant + montant,
      });
    };

    commandes
      .filter((commande) => (commande?.statut_paiement || '').toLowerCase() === 'paye')
      .forEach((commande) => {
        (commande.items || []).forEach((item) => {
          const modeleInfo = item.id_modele || {};
          const modeleId = typeof modeleInfo === 'object' ? modeleInfo._id : item.id_modele;
          const modeleNom = typeof modeleInfo === 'object' ? modeleInfo.nom : null;
          const modeleType = typeof modeleInfo === 'object' ? modeleInfo.type : null;
          const montantModele = toNumber(item.sous_total || item.prix_unitaire * item.quantite);
          addToMap(modeleMap, modeleId, modeleNom || 'Modele', modeleType, montantModele);

          (item.tissus || []).forEach((tissu) => {
            const tissuInfo = tissu.id_tissu || {};
            const tissuId = typeof tissuInfo === 'object' ? tissuInfo._id : tissu.id_tissu;
            const tissuNom = typeof tissuInfo === 'object' ? tissuInfo.nom : null;
            const tissuType = typeof tissuInfo === 'object' ? tissuInfo.type : null;
            const montantTissu = toNumber(tissu.sous_total);
            addToMap(tissuMap, tissuId, tissuNom || 'Tissu', tissuType, montantTissu);
          });
        });
      });

    const toSorted = (map) =>
      Array.from(map.values()).sort((a, b) => b.montant - a.montant).slice(0, 5);

    return {
      topModeles: toSorted(modeleMap),
      topTissus: toSorted(tissuMap),
    };
  }, [commandes]);

  const topModeleChartData = topModeles.map((item) => ({
    label: item.nom || 'Modele',
    value: item.montant,
  }));

  const topTissuChartData = topTissus.map((item) => ({
    label: item.nom || 'Tissu',
    value: item.montant,
  }));

  const paiementsFournisseurs = finance.expenses
    .filter((expense) => expense.type === 'fournisseur' && expense.statut !== 'paye')
    .slice(0, 3);

  return (
    <RequireAdmin>
      <main className="admin-shell">
        <NavBar />

        <section className="main">
          <div className="topline">
            <span className="breadcrumb">Pilotage ERP</span>
            <span className="date-text">{dateText}</span>
          </div>

          <h1 className="page-title">Vue globale du business</h1>
          <p className="subtitle">Finances, operations, commandes et campagnes au meme endroit.</p>

          <div className="erp-kpis three-col">
            <div className="kpi-card">
              <div className="kpi-head">
                <span className="kpi-icon">{kpiIcons.total}</span>
                <span>Chiffre d affaires total</span>
              </div>
              <strong>{formatAmount(totalRevenue)} FCFA</strong>
              <small>Sur mesure + tissus + pret a porter</small>
            </div>
            <div className="kpi-card">
              <div className="kpi-head">
                <span className="kpi-icon">{kpiIcons.tissu}</span>
                <span>Chiffre d affaires tissus</span>
              </div>
              <strong>{formatAmount(tissuRevenue)} FCFA</strong>
              <small>Ventes reseaux sociaux</small>
            </div>
            <div className="kpi-card">
              <div className="kpi-head">
                <span className="kpi-icon">{kpiIcons.pret}</span>
                <span>Chiffre d affaires pret a porter</span>
              </div>
              <strong>{formatAmount(pretRevenue)} FCFA</strong>
              <small>Boutique physique + DM</small>
            </div>
            <div className="kpi-card">
              <div className="kpi-head">
                <span className="kpi-icon">{kpiIcons.sur}</span>
                <span>Chiffre d affaires sur mesure</span>
              </div>
              <strong>{formatAmount(surMesureRevenue)} FCFA</strong>
              <small>Commandes payees</small>
            </div>
            <div className="kpi-card">
              <div className="kpi-head">
                <span className="kpi-icon">{kpiIcons.sorties}</span>
                <span>Sorties enregistrees</span>
              </div>
              <strong>{formatAmount(totalExpenses)} FCFA</strong>
              <small>Marketing, fournisseurs, logistique</small>
            </div>
            <div className="kpi-card">
              <div className="kpi-head">
                <span className="kpi-icon">{kpiIcons.caisse}</span>
                <span>Disponibilite caisse</span>
              </div>
              <strong>{formatAmount(caisse)} FCFA</strong>
              <small>Solde net</small>
            </div>
          </div>

          <div className="erp-grid">
            <section className="section-card">
              <div className="section-head">
                <div>
                  <h3>Repartition du chiffre d affaires</h3>
                  <p>Segmentation par activite</p>
                </div>
                <Link href="/admin/finances" className="ghost-link">Ouvrir finances</Link>
              </div>
              <div className="segment-list">
                {segments.map((segment) => (
                  <div key={segment.label} className="segment-row">
                    <div className="segment-label">{segment.label}</div>
                    <div className="segment-meter">
                      <span style={{ width: `${(segment.value / totalSegments) * 100}%`, background: segment.color }} />
                    </div>
                    <div className="segment-value">{formatAmount(segment.value)} FCFA</div>
                  </div>
                ))}
              </div>
            </section>

            <section className="section-card">
              <div className="section-head">
                <div>
                  <h3>Operations en cours</h3>
                  <p>Taches et campagnes prioritaires</p>
                </div>
                <Link href="/admin/operations" className="ghost-link">Gerer operations</Link>
              </div>
              <div className="pill-row">
                <span className="pill warning">{tasksEnAttente} taches a faire</span>
                <span className="pill muted">{tasksEnCours} en cours</span>
                <span className="pill success">{campagnesActives} campagnes actives</span>
              </div>
              <div className="list-stack">
                {tasks.slice(0, 3).map((task) => (
                  <div key={task.id} className="list-item">
                    <div>
                      <h4>{task.title}</h4>
                      <p>Echeance: {task.dueDate || 'non definie'} - {task.owner || 'Equipe'}</p>
                    </div>
                    <span className={`tag ${task.statut}`}>{task.statut.replace('_', ' ')}</span>
                  </div>
                ))}
                {tasks.length === 0 && <p className="muted-text">Aucune tache enregistre.</p>}
              </div>
            </section>
          </div>

          <div className="charts-grid">
            <LineChart
              data={dailySeries}
              dataKey="revenue"
              title="Revenu encaisse par jour"
              color="#c27a0f"
              yFormatter={formatCompact}
            />
            <LineChart
              data={dailySeries}
              dataKey="cash"
              title="Flux de caisse net"
              color="#2b1a0a"
              yFormatter={formatCompact}
            />
          </div>

          <section className="section-card">
            <div className="section-head">
              <div>
                <h3>Produits les plus rentables</h3>
                <p>Repartition des produits qui generent le plus de chiffre d affaires</p>
              </div>
            </div>
            <div className="charts-grid">
              <BarChart data={topModeleChartData} title="Top modeles" color="#d89a08" />
              <BarChart data={topTissuChartData} title="Top tissus" color="#2b1a0a" />
            </div>
          </section>

          <div className="erp-grid">
            <section className="section-card">
              <div className="section-head">
                <div>
                  <h3>Commandes & suivi</h3>
                  <p>Etat global des commandes sur mesure</p>
                </div>
                <Link href="/admin/commandes" className="ghost-link">Voir commandes</Link>
              </div>
              <div className="mini-kpis">
                <div>
                  <span>En attente</span>
                  <strong>{commandesCounts.en_attente}</strong>
                </div>
                <div>
                  <span>En cours</span>
                  <strong>{commandesCounts.en_cours}</strong>
                </div>
                <div>
                  <span>Terminee</span>
                  <strong>{commandesCounts.terminee}</strong>
                </div>
                <div>
                  <span>Annulee</span>
                  <strong>{commandesCounts.annulee}</strong>
                </div>
              </div>
              <div className="list-stack">
                {commandes.slice(0, 3).map((commande) => (
                  <div key={commande._id} className="list-item">
                    <div>
                      <h4>{commande.numero_commande}</h4>
                      <p>{commande.id_client?.prenom || 'Client'} {commande.id_client?.nom || ''}</p>
                    </div>
                    <span className={`tag ${normalizeStatutCommande(commande)}`}>{normalizeStatutCommande(commande)}</span>
                  </div>
                ))}
                {commandes.length === 0 && <p className="muted-text">Aucune commande chargee.</p>}
              </div>
            </section>

            <section className="section-card">
              <div className="section-head">
                <div>
                  <h3>Paiements fournisseurs</h3>
                  <p>Regler apres validation de commande</p>
                </div>
                <Link href="/admin/finances" className="ghost-link">Voir sorties</Link>
              </div>
              <div className="list-stack">
                {paiementsFournisseurs.map((expense) => (
                  <div key={expense.id} className="list-item">
                    <div>
                      <h4>{expense.label}</h4>
                      <p>{expense.beneficiaire || 'Fournisseur'} - {expense.date}</p>
                    </div>
                    <span className="pill danger">{formatAmount(expense.montant)} FCFA</span>
                  </div>
                ))}
                {paiementsFournisseurs.length === 0 && (
                  <p className="muted-text">Aucun paiement fournisseur en attente.</p>
                )}
              </div>
              <div className="quick-actions">
                <Link href="/admin/finances" className="action-link">Ajouter une sortie</Link>
                <Link href="/admin/operations" className="action-link">Planifier une tache</Link>
              </div>
            </section>
          </div>
        </section>
      </main>
    </RequireAdmin>
  );
}
