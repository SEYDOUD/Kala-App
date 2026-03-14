'use client';

import { Fragment, useEffect, useMemo, useState } from 'react';
import NavBar from '@/components/NavBar';
import RequireAdmin from '@/components/RequireAdmin';
import { apiRequest, uploadSingleImage, uploadSingleVideo } from '@/lib/api';

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

export default function CommandesPage() {
  const [commandes, setCommandes] = useState([]);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [openResultatId, setOpenResultatId] = useState(null);
  const [resultatDrafts, setResultatDrafts] = useState({});
  const [detailCommande, setDetailCommande] = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [detailError, setDetailError] = useState('');

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

  const suiviCounts = STATUTS_SUIVI.reduce((acc, item) => {
    const total = commandes.filter((c) => normalizeSuivi(c.statut) === item.value).length;
    acc[item.value] = total;
    return acc;
  }, {});

  const updateSuivi = async (id, statut) => {
    await apiRequest(`/api/commandes/${id}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ statut }),
    });
    loadCommandes();
  };

  const updateStatutCommande = async (id, statut_commande) => {
    await apiRequest(`/api/commandes/${id}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ statut_commande }),
    });
    loadCommandes();
  };

  const updateDeliveryDate = async (id, dateValue) => {
    await apiRequest(`/api/commandes/${id}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ date_livraison_estimee: dateValue || null }),
    });
    loadCommandes();
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
    const id = commande._id;
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
              <p className="subtitle">{filtered.length} commandes au total</p>
            </div>
            <div className="icon-square">CMD</div>
          </div>

          <div className="stats-grid single-row">
            {STATUTS_SUIVI.map((item) => (
              <div className="stats-card" key={item.value}>
                <div className="value">{suiviCounts[item.value] || 0}</div>
                <div className="label">{item.label}</div>
              </div>
            ))}
          </div>

          <div className="panel search-wide">
            <input placeholder="Rechercher par numero ou client..." value={search} onChange={(e) => setSearch(e.target.value)} />
          </div>

          {error ? <p className="error-text">{error}</p> : null}

          <div className="panel table-wrap" style={{ padding: 18 }}>
            <table className="table modern compact">
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
                  const draft = resultatDrafts[commande._id] || {};
                  const photosCount = commande.resultat_couture?.photos?.length || 0;
                  const videosCount = commande.resultat_couture?.videos?.length || 0;
                  const currentSuiviLabel = getSuiviLabel(commande.statut);
                  const nextSuivi = getNextSuiviValue(commande.statut);
                  const prevSuivi = getPrevSuiviValue(commande.statut);
                  const livraisonValue = toDateInputValue(commande.date_livraison_estimee);
                  const photoList = parseUrls(draft.photos || '');
                  const videoList = parseUrls(draft.videos || '');
                  const canChangeStatutCommande = statutCommande !== 'terminee';

                  return (
                    <Fragment key={commande._id}>
                      <tr>
                        <td>
                          <button
                            type="button"
                            className="link-button"
                            onClick={() => openDetails(commande._id)}
                            title="Voir les details"
                          >
                            {commande.numero_commande}
                          </button>
                        </td>
                        <td>
                          <span
                            className="cell-ellipsis"
                            title={`${commande.id_client?.prenom || ''} ${commande.id_client?.nom || ''}`}
                          >
                            {commande.id_client?.prenom} {commande.id_client?.nom}
                          </span>
                        </td>
                        <td>{commande.montant_total} FCFA</td>
                        <td>
                          <input
                            type="date"
                            value={livraisonValue}
                            onChange={(e) => updateDeliveryDate(commande._id, e.target.value)}
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
                                onClick={() => markPaymentAsPaid(commande._id)}
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
                              onClick={() => prevSuivi && updateSuivi(commande._id, prevSuivi)}
                            >
                              Prec
                            </button>
                            <span className="pill muted">{currentSuiviLabel}</span>
                            <button
                              className="secondary"
                              disabled={!nextSuivi}
                              onClick={() => nextSuivi && updateSuivi(commande._id, nextSuivi)}
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
                              onChange={(e) => updateStatutCommande(commande._id, e.target.value)}
                            >
                              {STATUTS_COMMANDE.map((statut) => (
                                <option key={statut.value} value={statut.value}>{statut.label}</option>
                              ))}
                            </select>
                          </div>
                        </td>
                        <td>
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
                        </td>
                      </tr>
                      {openResultatId === commande._id && (
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
        </section>
      </main>
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




