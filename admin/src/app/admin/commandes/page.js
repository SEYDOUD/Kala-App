'use client';

import { useEffect, useMemo, useState } from 'react';
import NavBar from '@/components/NavBar';
import RequireAdmin from '@/components/RequireAdmin';
import { apiRequest } from '@/lib/api';

const STATUTS = ['en_attente', 'confirmee', 'en_cours', 'prete', 'livree', 'annulee'];

export default function CommandesPage() {
  const [commandes, setCommandes] = useState([]);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');

  const dateText = useMemo(
    () => new Date().toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }),
    []
  );

  const loadCommandes = async () => {
    try {
      const data = await apiRequest('/api/commandes');
      setCommandes(data.commandes || []);
      setError('');
    } catch (err) {
      setError(err.message);
    }
  };

  useEffect(() => {
    loadCommandes();
  }, []);

  const filtered = commandes.filter((item) => {
    const client = `${item.id_client?.prenom || ''} ${item.id_client?.nom || ''}`.toLowerCase();
    return item.numero_commande?.toLowerCase().includes(search.toLowerCase()) || client.includes(search.toLowerCase());
  });

  const counts = {
    en_attente: filtered.filter((c) => c.statut === 'en_attente').length,
    confirmee: filtered.filter((c) => c.statut === 'confirmee').length,
    en_cours: filtered.filter((c) => c.statut === 'en_cours').length,
    prete: filtered.filter((c) => c.statut === 'prete').length,
    livree: filtered.filter((c) => c.statut === 'livree').length,
    annulee: filtered.filter((c) => c.statut === 'annulee').length,
  };

  const updateStatus = async (id, statut) => {
    await apiRequest(`/api/commandes/${id}/status`, { method: 'PATCH', body: JSON.stringify({ statut }) });
    loadCommandes();
  };

  return (
    <RequireAdmin>
      <main className="admin-shell">
        <NavBar />
        <section className="main">
          <div className="topline">
            <span style={{ fontSize: 18 }}>✕</span>
            <span className="date-text">{dateText}</span>
          </div>

          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
            <div>
              <h1 className="page-title">Suivi et livraison des commandes</h1>
              <p className="subtitle">{filtered.length} commandes au total</p>
            </div>
            <div className="icon-square">▢</div>
          </div>

          <div className="stats-grid compact-six">
            <div className="stats-card"><div className="value">{counts.en_attente}</div><div className="label">En attente</div></div>
            <div className="stats-card"><div className="value">{counts.confirmee}</div><div className="label">Confirmée</div></div>
            <div className="stats-card"><div className="value">{counts.en_cours}</div><div className="label">En cours</div></div>
            <div className="stats-card"><div className="value">{counts.prete}</div><div className="label">Prête</div></div>
            <div className="stats-card"><div className="value">{counts.livree}</div><div className="label">Livrée</div></div>
            <div className="stats-card"><div className="value">{counts.annulee}</div><div className="label">Annulée</div></div>
          </div>

          <div className="panel">
            <input placeholder="Rechercher par numéro ou client..." value={search} onChange={(e) => setSearch(e.target.value)} />
          </div>

          {error ? <p className="error-text">{error}</p> : null}

          <div className="panel table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>N° Commande</th>
                  <th>Client</th>
                  <th>Total</th>
                  <th>Paiement</th>
                  <th>Statut</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((commande) => (
                  <tr key={commande._id}>
                    <td>{commande.numero_commande}</td>
                    <td>{commande.id_client?.prenom} {commande.id_client?.nom}</td>
                    <td>{commande.montant_total} FCFA</td>
                    <td>
                      <span className={`pill ${commande.statut_paiement === 'paye' ? 'success' : 'warning'}`}>
                        {commande.statut_paiement === 'paye' ? 'Payée' : 'En attente'}
                      </span>
                    </td>
                    <td>
                      <select value={commande.statut} onChange={(e) => updateStatus(commande._id, e.target.value)}>
                        {STATUTS.map((statut) => (
                          <option key={statut} value={statut}>{statut}</option>
                        ))}
                      </select>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      </main>
    </RequireAdmin>
  );
}
