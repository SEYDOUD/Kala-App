'use client';

import { useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import NavBar from '@/components/NavBar';
import RequireAdmin from '@/components/RequireAdmin';
import {
  OPS_STORAGE_KEY,
  createSeedOperations,
  loadStoredData,
  saveStoredData,
} from '@/lib/erpStorage';

const TASK_STATUSES = [
  { value: 'a_faire', label: 'A faire' },
  { value: 'en_cours', label: 'En cours' },
  { value: 'fait', label: 'Terminee' },
];

const CAMPAIGN_STATUSES = [
  { value: 'planifiee', label: 'Planifiee' },
  { value: 'active', label: 'Active' },
  { value: 'terminee', label: 'Terminee' },
];

function todayString() {
  return new Date().toISOString().slice(0, 10);
}

function formatAmount(value) {
  return new Intl.NumberFormat('fr-FR').format(value || 0);
}

function buildDefaultTaskForm() {
  return {
    title: '',
    owner: '',
    priority: 'moyenne',
    dueDate: todayString(),
    statut: 'a_faire',
  };
}

function buildDefaultCampaignForm() {
  return {
    name: '',
    canal: 'Instagram',
    budget: '',
    startDate: todayString(),
    endDate: todayString(),
    statut: 'planifiee',
    objectif: '',
  };
}

export default function OperationsPage() {
  const searchParams = useSearchParams();
  const tabParam = searchParams.get('tab');
  const [operations, setOperations] = useState(createSeedOperations());
  const [taskForm, setTaskForm] = useState(buildDefaultTaskForm());
  const [campaignForm, setCampaignForm] = useState(buildDefaultCampaignForm());
  const [error, setError] = useState('');
  const [activeTab, setActiveTab] = useState('taches');

  const dateText = useMemo(
    () => new Date().toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }),
    []
  );

  useEffect(() => {
    setOperations(loadStoredData(OPS_STORAGE_KEY, createSeedOperations));
  }, []);

  useEffect(() => {
    if (tabParam === 'campagnes') {
      setActiveTab('campagnes');
      return;
    }
    setActiveTab('taches');
  }, [tabParam]);

  useEffect(() => {
    saveStoredData(OPS_STORAGE_KEY, operations);
  }, [operations]);

  const tasks = operations.tasks || [];
  const campaigns = operations.campaigns || [];

  const tasksByStatus = TASK_STATUSES.reduce((acc, status) => {
    acc[status.value] = tasks.filter((task) => task.statut === status.value);
    return acc;
  }, {});

  const addTask = () => {
    if (!taskForm.title) {
      setError('Renseigne un titre de tache.');
      return;
    }
    const newTask = {
      ...taskForm,
      id: `task-${Date.now()}`,
    };
    setOperations((prev) => ({ ...prev, tasks: [newTask, ...prev.tasks] }));
    setTaskForm(buildDefaultTaskForm());
    setError('');
  };

  const addCampaign = () => {
    if (!campaignForm.name) {
      setError('Renseigne un nom de campagne.');
      return;
    }
    const newCampaign = {
      ...campaignForm,
      id: `camp-${Date.now()}`,
      budget: campaignForm.budget ? Number(campaignForm.budget) : 0,
    };
    setOperations((prev) => ({ ...prev, campaigns: [newCampaign, ...prev.campaigns] }));
    setCampaignForm(buildDefaultCampaignForm());
    setError('');
  };

  const moveTask = (id, statut) => {
    setOperations((prev) => ({
      ...prev,
      tasks: prev.tasks.map((task) => (task.id === id ? { ...task, statut } : task)),
    }));
  };

  const updateCampaignStatus = (id, statut) => {
    setOperations((prev) => ({
      ...prev,
      campaigns: prev.campaigns.map((campaign) => (campaign.id === id ? { ...campaign, statut } : campaign)),
    }));
  };

  return (
    <RequireAdmin>
      <main className="admin-shell">
        <NavBar />

        <section className="main">
          <div className="topline">
            <span className="breadcrumb">Operations</span>
            <span className="date-text">{dateText}</span>
          </div>

          <h1 className="page-title">Planification & campagnes</h1>
          <p className="subtitle">Organisation des taches atelier et campagnes de communication.</p>

          {error && <p className="error-text">{error}</p>}

          {activeTab === 'taches' ? (
            <>
              <div className="erp-grid">
                <section className="section-card">
                  <div className="section-head">
                    <div>
                      <h3>Ajouter une tache</h3>
                      <p>Planifie l atelier, les commandes et la com</p>
                    </div>
                  </div>
                  <div className="form-grid">
                    <div className="field-group">
                      <label className="field-label">Titre</label>
                      <input
                        value={taskForm.title}
                        onChange={(event) => setTaskForm({ ...taskForm, title: event.target.value })}
                        placeholder="Ex: Preparer patron"
                      />
                    </div>
                    <div className="field-group">
                      <label className="field-label">Responsable</label>
                      <input
                        value={taskForm.owner}
                        onChange={(event) => setTaskForm({ ...taskForm, owner: event.target.value })}
                        placeholder="Atelier / Equipe"
                      />
                    </div>
                    <div className="field-group">
                      <label className="field-label">Priorite</label>
                      <select value={taskForm.priority} onChange={(event) => setTaskForm({ ...taskForm, priority: event.target.value })}>
                        <option value="haute">Haute</option>
                        <option value="moyenne">Moyenne</option>
                        <option value="basse">Basse</option>
                      </select>
                    </div>
                    <div className="field-group">
                      <label className="field-label">Echeance</label>
                      <input
                        type="date"
                        value={taskForm.dueDate}
                        onChange={(event) => setTaskForm({ ...taskForm, dueDate: event.target.value })}
                      />
                    </div>
                  </div>
                  <div className="toolbar">
                    <button onClick={addTask}>Ajouter la tache</button>
                  </div>
                </section>
              </div>

              <section className="section-card">
                <div className="section-head">
                  <div>
                    <h3>Tableau des taches</h3>
                    <p>Suivi par statut</p>
                  </div>
                </div>
                <div className="kanban-grid">
                  {TASK_STATUSES.map((status) => (
                    <div key={status.value} className="kanban-col">
                      <div className="kanban-head">
                        <h4>{status.label}</h4>
                        <span>{tasksByStatus[status.value]?.length || 0}</span>
                      </div>
                      <div className="kanban-list">
                        {(tasksByStatus[status.value] || []).map((task) => (
                          <div key={task.id} className="kanban-card">
                            <h5>{task.title}</h5>
                            <p>Responsable: {task.owner || 'Equipe'}</p>
                            <p>Echeance: {task.dueDate || '-'}</p>
                            <div className="pill-row">
                              <span className={`pill ${task.priority === 'haute' ? 'danger' : task.priority === 'basse' ? 'muted' : 'warning'}`}>
                                {task.priority}
                              </span>
                              {status.value !== 'a_faire' && (
                                <button className="secondary" onClick={() => moveTask(task.id, 'a_faire')}>Revenir</button>
                              )}
                              {status.value !== 'en_cours' && (
                                <button className="secondary" onClick={() => moveTask(task.id, 'en_cours')}>Lancer</button>
                              )}
                              {status.value !== 'fait' && (
                                <button className="secondary" onClick={() => moveTask(task.id, 'fait')}>Terminer</button>
                              )}
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              </section>
            </>
          ) : (
            <>
              <div className="erp-grid">
                <section className="section-card">
                  <div className="section-head">
                    <div>
                      <h3>Ajouter une campagne</h3>
                      <p>Planifie les campagnes reseaux sociaux</p>
                    </div>
                  </div>
                  <div className="form-grid">
                    <div className="field-group">
                      <label className="field-label">Nom campagne</label>
                      <input
                        value={campaignForm.name}
                        onChange={(event) => setCampaignForm({ ...campaignForm, name: event.target.value })}
                        placeholder="Ex: Promo tissus"
                      />
                    </div>
                    <div className="field-group">
                      <label className="field-label">Canal</label>
                      <input
                        value={campaignForm.canal}
                        onChange={(event) => setCampaignForm({ ...campaignForm, canal: event.target.value })}
                      />
                    </div>
                    <div className="field-group">
                      <label className="field-label">Budget</label>
                      <input
                        type="number"
                        value={campaignForm.budget}
                        onChange={(event) => setCampaignForm({ ...campaignForm, budget: event.target.value })}
                      />
                    </div>
                    <div className="field-group">
                      <label className="field-label">Debut</label>
                      <input
                        type="date"
                        value={campaignForm.startDate}
                        onChange={(event) => setCampaignForm({ ...campaignForm, startDate: event.target.value })}
                      />
                    </div>
                    <div className="field-group">
                      <label className="field-label">Fin</label>
                      <input
                        type="date"
                        value={campaignForm.endDate}
                        onChange={(event) => setCampaignForm({ ...campaignForm, endDate: event.target.value })}
                      />
                    </div>
                    <div className="field-group">
                      <label className="field-label">Objectif</label>
                      <input
                        value={campaignForm.objectif}
                        onChange={(event) => setCampaignForm({ ...campaignForm, objectif: event.target.value })}
                        placeholder="Ex: Conversion"
                      />
                    </div>
                  </div>
                  <div className="toolbar">
                    <button onClick={addCampaign}>Ajouter campagne</button>
                  </div>
                </section>
              </div>

              <section className="section-card">
                <div className="section-head">
                  <div>
                    <h3>Campagnes de communication</h3>
                    <p>Planifiees, actives et terminees</p>
                  </div>
                </div>
                <div className="table-wrap">
                  <table className="table modern compact">
                    <thead>
                      <tr>
                        <th>Campagne</th>
                        <th>Canal</th>
                        <th>Budget</th>
                        <th>Periode</th>
                        <th>Objectif</th>
                        <th>Statut</th>
                      </tr>
                    </thead>
                    <tbody>
                      {campaigns.map((campaign) => (
                        <tr key={campaign.id}>
                          <td>{campaign.name}</td>
                          <td>{campaign.canal}</td>
                          <td>{formatAmount(campaign.budget)} FCFA</td>
                          <td>{campaign.startDate} - {campaign.endDate}</td>
                          <td><span className="cell-ellipsis">{campaign.objectif || '-'}</span></td>
                          <td>
                            <select
                              value={campaign.statut}
                              onChange={(event) => updateCampaignStatus(campaign.id, event.target.value)}
                            >
                              {CAMPAIGN_STATUSES.map((status) => (
                                <option key={status.value} value={status.value}>{status.label}</option>
                              ))}
                            </select>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </section>
            </>
          )}
        </section>
      </main>
    </RequireAdmin>
  );
}
