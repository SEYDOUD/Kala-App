'use client';

import { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import NavBar from '@/components/NavBar';
import RequireAdmin from '@/components/RequireAdmin';
import { apiRequest } from '@/lib/api';

const DAY_RANGE = 7;

function startOfDay(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
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

function toNumber(value) {
  const amount = Number(value);
  return Number.isFinite(amount) ? amount : 0;
}

function buildDailySeries(commandes, dayRange = DAY_RANGE) {
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
      orders: 0,
    });
  }

  commandes.forEach((commande) => {
    if (!commande?.createdAt) {
      return;
    }

    const createdAt = new Date(commande.createdAt);
    if (Number.isNaN(createdAt.getTime())) {
      return;
    }

    const normalizedDate = startOfDay(createdAt);
    const key = normalizedDate.toISOString().slice(0, 10);
    const day = dayMap.get(key);

    if (!day) {
      return;
    }

    day.orders += 1;
    day.revenue += toNumber(commande.montant_total);
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



export default function DashboardPage() {
  const [stats, setStats] = useState({ modeles: 0, tissus: 0, commandes: 0, enCours: 0 });
  const [totalRevenue, setTotalRevenue] = useState(0);
  const [dailySeries, setDailySeries] = useState(buildDailySeries([]));

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
        const revenue = list.reduce((sum, item) => sum + toNumber(item.montant_total), 0);
        setTotalRevenue(revenue);
        setDailySeries(buildDailySeries(list));

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
          <p className="subtitle">Bienvenue dans votre espace d’administration KALA</p>

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
              <p>{formatAmount(totalRevenue)} FCFA</p>
            </div>
            <div className="revenue-bottom">Données mises à jour depuis les commandes enregistrées</div>
          </div>

          <div className="charts-grid">
            <LineChart
              data={dailySeries}
              dataKey="revenue"
              title="Évolution du revenu total par jour"
              color="#c27a0f"
              yFormatter={formatCompact}
            />
            <LineChart
              data={dailySeries}
              dataKey="orders"
              title="Évolution des commandes journalières"
              color="#2b1a0a"
              yFormatter={(value) => value}
            />
          </div>
        </section>
      </main>
    </RequireAdmin>
  );
}
