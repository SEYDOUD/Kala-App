'use client';

import { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import NavBar from '@/components/NavBar';
import RequireAdmin from '@/components/RequireAdmin';
import { apiRequest } from '@/lib/api';

export default function DashboardPage() {
  const [stats, setStats] = useState({ modeles: 0, tissus: 0, commandes: 0, enCours: 0 });

  const dateText = useMemo(
    () => new Date().toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }),
    []
  );

  useEffect(() => {
    async function load() {
      try {
        const [modeles, tissus, commandes] = await Promise.all([
          apiRequest('/api/modeles?limit=100'),
          apiRequest('/api/tissus?limit=100'),
          apiRequest('/api/commandes'),
        ]);

        const list = commandes.commandes || [];
        setStats({
          modeles: modeles.total || 0,
          tissus: tissus.total || 0,
          commandes: list.length,
          enCours: list.filter((item) => item.statut === 'en_cours').length,
        });
      } catch {
        // ignore fetch errors on dashboard
      }
    }
    load();
  }, []);

  return (
    <RequireAdmin>
      <main className="admin-shell">
        <NavBar />

        <section className="main">
          <div className="topline">
            <span style={{ fontSize: 18 }}>✕</span>
            <span className="date-text">{dateText}</span>
          </div>

          <h1 className="page-title">Tableau de bord</h1>
          <p className="subtitle">Bienvenue dans votre espace d'administration KALA</p>

          <div className="stats-grid">
            <Link href="/admin/modeles" className="stats-card">
              <div>Modèles</div>
              <p className="value">{stats.modeles}</p>
              <div className="label">Catalogue total</div>
            </Link>
            <Link href="/admin/tissus" className="stats-card">
              <div>Tissus</div>
              <p className="value">{stats.tissus}</p>
              <div className="label">Matières disponibles</div>
            </Link>
            <Link href="/admin/commandes" className="stats-card">
              <div>Commandes</div>
              <p className="value">{stats.commandes}</p>
              <div className="label">Total général</div>
            </Link>
            <Link href="/admin/commandes" className="stats-card">
              <div>En cours</div>
              <p className="value">{stats.enCours}</p>
              <div className="label">À traiter</div>
            </Link>
          </div>

          <div className="revenue">
            <div className="revenue-top">
              <h3>Revenu total</h3>
              <p>365 000 FCFA</p>
            </div>
            <div className="revenue-bottom">↗ +12.5% ce mois</div>
          </div>
        </section>
      </main>
    </RequireAdmin>
  );
}
