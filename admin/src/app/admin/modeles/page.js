'use client';

import { useEffect, useMemo, useState } from 'react';
import NavBar from '@/components/NavBar';
import RequireAdmin from '@/components/RequireAdmin';
import { apiRequest, uploadSingleImage } from '@/lib/api';

const initialForm = {
  id_atelier: '',
  nom: '',
  description: '',
  genre: 'unisexe',
  prix: '',
  duree_conception: 7,
};

export default function ModelesPage() {
  const [modeles, setModeles] = useState([]);
  const [ateliers, setAteliers] = useState([]);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [genre, setGenre] = useState('');
  const [form, setForm] = useState(initialForm);
  const [imageFile, setImageFile] = useState(null);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [editingModeleId, setEditingModeleId] = useState('');
  const [editForm, setEditForm] = useState({
    nom: '',
    description: '',
    genre: 'unisexe',
    prix: '',
    duree_conception: 7,
    currentImageUrl: ''
  });
  const [editImageFile, setEditImageFile] = useState(null);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [modeleToDelete, setModeleToDelete] = useState(null);

  const dateText = useMemo(
    () => new Date().toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }),
    []
  );

  const loadModeles = async () => {
    try {
      const data = await apiRequest('/api/modeles/admin/all?limit=100');
      setModeles(data.modeles || []);
      setError('');
    } catch (err) {
      setError(err.message);
    }
  };

  const loadAteliers = async () => {
    try {
      const data = await apiRequest('/api/modeles/admin/ateliers');
      setAteliers(data.ateliers || []);
      if (!form.id_atelier && data.ateliers?.length) {
        setForm((prev) => ({ ...prev, id_atelier: data.ateliers[0]._id }));
      }
    } catch {
      // garder silencieux, l'erreur générale sera gérée au submit
    }
  };

  useEffect(() => {
    loadModeles();
    loadAteliers();
  }, []);

  const filtered = modeles.filter((item) => {
    const matchSearch = item.nom?.toLowerCase().includes(search.toLowerCase());
    const matchGenre = !genre || item.genre === genre;
    return matchSearch && matchGenre;
  });

  const toggleActif = async (modele) => {
    await apiRequest(`/api/modeles/${modele._id}`, { method: 'PUT', body: JSON.stringify({ actif: !modele.actif }) });
    loadModeles();
  };

  const askDeleteModele = (modele) => {
    setModeleToDelete(modele);
    setShowDeleteConfirm(true);
  };

  const confirmDeleteModele = async () => {
    if (!modeleToDelete?._id) return;

    try {
      await apiRequest(`/api/modeles/${modeleToDelete._id}`, { method: 'DELETE' });
      setShowDeleteConfirm(false);
      setModeleToDelete(null);
      loadModeles();
    } catch (err) {
      setError(err.message);
    }
  };

  const getModeleImageUrl = (modele) => {
    if (Array.isArray(modele.images) && modele.images.length > 0) {
      return modele.images[0]?.url || '';
    }
    return '';
  };

  const openEditModal = (modele) => {
    setEditingModeleId(modele._id);
    setEditForm({
      nom: modele.nom || '',
      description: modele.description || '',
      genre: modele.genre || 'unisexe',
      prix: modele.prix || '',
      duree_conception: modele.duree_conception ?? 7,
      currentImageUrl: getModeleImageUrl(modele),
    });
    setEditImageFile(null);
    setShowEditModal(true);
  };

  const updateModele = async (event) => {
    event.preventDefault();

    try {
      let images;
      if (editImageFile) {
        const upload = await uploadSingleImage(editImageFile);
        if (upload?.image?.url) {
          images = [{ url: upload.image.url, alt: editForm.nom }];
        }
      }

      const payload = {
        nom: editForm.nom,
        description: editForm.description,
        genre: editForm.genre,
        prix: Number(editForm.prix),
        duree_conception: Number(editForm.duree_conception) || 7,
      };

      if (images) {
        payload.images = images;
      }

      await apiRequest(`/api/modeles/${editingModeleId}`, {
        method: 'PUT',
        body: JSON.stringify(payload),
      });

      setShowEditModal(false);
      setEditingModeleId('');
      setEditImageFile(null);
      loadModeles();
    } catch (err) {
      setError(err.message);
    }
  };

  const createModele = async (event) => {
    event.preventDefault();

    try {
      let images = [];
      if (imageFile) {
        const upload = await uploadSingleImage(imageFile);
        if (upload?.image?.url) {
          images = [{ url: upload.image.url, alt: form.nom }];
        }
      }

      await apiRequest('/api/modeles', {
        method: 'POST',
        body: JSON.stringify({
          id_atelier: form.id_atelier,
          nom: form.nom,
          description: form.description,
          genre: form.genre,
          prix: Number(form.prix),
          duree_conception: Number(form.duree_conception) || 7,
          images,
        }),
      });

      setForm((prev) => ({ ...initialForm, id_atelier: prev.id_atelier }));
      setImageFile(null);
      setShowCreateModal(false);
      loadModeles();
    } catch (err) {
      setError(err.message);
    }
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

          <h1 className="page-title">Gestion des modèles</h1>
          <p className="subtitle">{filtered.length} modèles (actifs + inactifs)</p>

          <div className="toolbar">
            <button className="create-modele-btn" onClick={() => setShowCreateModal(true)}><span aria-hidden="true">＋</span> Créer un modèle</button>
          </div>

          <div className="panel row search">
            <input placeholder="Rechercher un modèle..." value={search} onChange={(e) => setSearch(e.target.value)} />
            <select value={genre} onChange={(e) => setGenre(e.target.value)}>
              <option value="">Tous les genres</option>
              <option value="homme">Homme</option>
              <option value="femme">Femme</option>
              <option value="unisexe">Unisexe</option>
            </select>
          </div>

          {error ? <p className="error-text">{error}</p> : null}

          <div className="panel table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>Image</th>
                  <th>Nom</th>
                  <th>Genre</th>
                  <th>Prix</th>
                  <th>Statut</th>
                  <th>Activation</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((modele) => (
                  <tr key={modele._id}>
                    <td>
                      {getModeleImageUrl(modele) ? (
                        <img className="modele-thumb" src={getModeleImageUrl(modele)} alt={modele.nom} />
                      ) : (
                        <span className="thumb-placeholder">Aucune</span>
                      )}
                    </td>
                    <td>{modele.nom}</td>
                    <td>{modele.genre}</td>
                    <td>{modele.prix} FCFA</td>
                    <td>
                      <span className={`pill ${modele.actif ? 'success' : 'muted'}`}>{modele.actif ? 'Actif' : 'Inactif'}</span>
                    </td>
                    <td>
                      <label className="switch">
                        <input type="checkbox" checked={modele.actif} onChange={() => toggleActif(modele)} />
                        <span className="slider" />
                      </label>
                    </td>
                    <td className="table-actions-cell">
                      <div className="actions">
                        <button className="info icon-only" onClick={() => openEditModal(modele)} title="Modifier" aria-label="Modifier">
                          <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">
                            <path d="M3 17.25V21h3.75l11-11-3.75-3.75-11 11z" />
                            <path d="M20.71 7.04a1 1 0 0 0 0-1.41L18.37 3.3a1 1 0 0 0-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.84z" />
                          </svg>
                        </button>
                        <button className="danger icon-only" onClick={() => askDeleteModele(modele)} title="Supprimer" aria-label="Supprimer">
                          <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">
                            <path d="M6 7h12l-1 13H7L6 7zm3-3h6l1 2h4v2H4V6h4l1-2z" />
                          </svg>
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {showDeleteConfirm ? (
            <div className="modal-overlay" onClick={() => setShowDeleteConfirm(false)}>
              <div className="modal-card" onClick={(event) => event.stopPropagation()}>
                <h3>Confirmer la suppression</h3>
                <p>
                  Voulez-vous vraiment supprimer le modèle{' '}
                  <strong>{modeleToDelete?.nom || 'sélectionné'}</strong> ?
                </p>
                <div className="actions" style={{ marginTop: 12 }}>
                  <button type="button" className="danger" onClick={confirmDeleteModele}>Supprimer</button>
                  <button type="button" className="secondary" onClick={() => setShowDeleteConfirm(false)}>Annuler</button>
                </div>
              </div>
            </div>
          ) : null}

          {showEditModal ? (
            <div className="modal-overlay" onClick={() => setShowEditModal(false)}>
              <div className="modal-card" onClick={(event) => event.stopPropagation()}>
                <h3>Modifier le modèle</h3>
                <form className="row" onSubmit={updateModele}>
                  <div className="row search">
                    <input
                      placeholder="Nom du modèle"
                      value={editForm.nom}
                      onChange={(e) => setEditForm({ ...editForm, nom: e.target.value })}
                      required
                    />
                    <input
                      type="number"
                      placeholder="Prix"
                      value={editForm.prix}
                      onChange={(e) => setEditForm({ ...editForm, prix: e.target.value })}
                      required
                    />
                  </div>
                  <div className="row search">
                    <input
                      type="number"
                      min="1"
                      placeholder="Duree de conception (jours)"
                      value={editForm.duree_conception}
                      onChange={(e) => setEditForm({ ...editForm, duree_conception: e.target.value })}
                      required
                    />
                    <div />
                  </div>
                  <select value={editForm.genre} onChange={(e) => setEditForm({ ...editForm, genre: e.target.value })}>
                    <option value="homme">Homme</option>
                    <option value="femme">Femme</option>
                    <option value="unisexe">Unisexe</option>
                  </select>
                  <div className="row search">
                    <input
                      type="file"
                      accept="image/*"
                      onChange={(e) => setEditImageFile(e.target.files?.[0] || null)}
                    />
                    {editForm.currentImageUrl ? (
                      <img className="modele-thumb" src={editForm.currentImageUrl} alt="Image actuelle" />
                    ) : (
                      <span className="thumb-placeholder">Aucune</span>
                    )}
                  </div>
                  <textarea
                    placeholder="Description"
                    value={editForm.description}
                    onChange={(e) => setEditForm({ ...editForm, description: e.target.value })}
                  />
                  <div className="actions">
                    <button type="submit">Enregistrer</button>
                    <button type="button" className="secondary" onClick={() => setShowEditModal(false)}>Annuler</button>
                  </div>
                </form>
              </div>
            </div>
          ) : null}

          {showCreateModal ? (
            <div className="modal-overlay" onClick={() => setShowCreateModal(false)}>
              <div className="modal-card" onClick={(event) => event.stopPropagation()}>
                <h3>Créer un modèle</h3>
                <form className="row" onSubmit={createModele}>
                  <select
                    value={form.id_atelier}
                    onChange={(e) => setForm({ ...form, id_atelier: e.target.value })}
                    required
                  >
                    <option value="">Sélectionner un atelier</option>
                    {ateliers.map((atelier) => (
                      <option key={atelier._id} value={atelier._id}>{atelier.nom_atelier}</option>
                    ))}
                  </select>

                  <div className="row search">
                    <input
                      placeholder="Nom du modèle"
                      value={form.nom}
                      onChange={(e) => setForm({ ...form, nom: e.target.value })}
                      required
                    />
                    <input
                      type="number"
                      placeholder="Prix"
                      value={form.prix}
                      onChange={(e) => setForm({ ...form, prix: e.target.value })}
                      required
                    />
                  </div>
                  <div className="row search">
                    <input
                      type="number"
                      min="1"
                      placeholder="Duree de conception (jours)"
                      value={form.duree_conception}
                      onChange={(e) => setForm({ ...form, duree_conception: e.target.value })}
                      required
                    />
                    <div />
                  </div>
                  <div className="row search">
                    <select value={form.genre} onChange={(e) => setForm({ ...form, genre: e.target.value })}>
                      <option value="homme">Homme</option>
                      <option value="femme">Femme</option>
                      <option value="unisexe">Unisexe</option>
                    </select>
                    <input type="file" accept="image/*" onChange={(e) => setImageFile(e.target.files?.[0] || null)} />
                  </div>
                  <textarea
                    placeholder="Description"
                    value={form.description}
                    onChange={(e) => setForm({ ...form, description: e.target.value })}
                  />
                  <div className="actions">
                    <button type="submit">Créer</button>
                    <button type="button" className="secondary" onClick={() => setShowCreateModal(false)}>Annuler</button>
                  </div>
                </form>
              </div>
            </div>
          ) : null}
        </section>
      </main>
    </RequireAdmin>
  );
}
