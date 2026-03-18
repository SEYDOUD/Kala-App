'use client';

import { useEffect, useMemo, useState } from 'react';
import NavBar from '@/components/NavBar';
import RequireAdmin from '@/components/RequireAdmin';
import { apiRequest, uploadSingleImage } from '@/lib/api';

const emptyForm = {
  nom: '',
  description: '',
  genre: 'unisexe',
  type: '',
  prix: '',
  prix_fournisseur: '',
  couleur: '#d4af37',
};

export default function TissusPage() {
  const [tissus, setTissus] = useState([]);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [genre, setGenre] = useState('');

  const [form, setForm] = useState(emptyForm);
  const [imageFile, setImageFile] = useState(null);
  const [showCreateModal, setShowCreateModal] = useState(false);

  const [showEditModal, setShowEditModal] = useState(false);
  const [editingTissuId, setEditingTissuId] = useState('');
  const [editForm, setEditForm] = useState({ ...emptyForm, currentImageUrl: '' });
  const [editImageFile, setEditImageFile] = useState(null);

  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [tissuToDelete, setTissuToDelete] = useState(null);

  const dateText = useMemo(
    () => new Date().toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }),
    []
  );

  const getTissuImageUrl = (tissu) => {
    if (Array.isArray(tissu.images) && tissu.images.length > 0) {
      return tissu.images[0]?.url || '';
    }
    return '';
  };

  const loadTissus = async () => {
    try {
      const data = await apiRequest('/api/tissus/admin/all?limit=200');
      setTissus(data.tissus || []);
      setError('');
    } catch (err) {
      setError(err.message);
    }
  };

  useEffect(() => {
    loadTissus();
  }, []);

  const filtered = tissus.filter((item) => {
    const matchSearch = item.nom?.toLowerCase().includes(search.toLowerCase());
    const matchGenre = !genre || item.genre === genre;
    return matchSearch && matchGenre;
  });

  const toggleActif = async (tissu) => {
    await apiRequest(`/api/tissus/${tissu._id}`, {
      method: 'PUT',
      body: JSON.stringify({ actif: !tissu.actif }),
    });
    loadTissus();
  };

  const askDeleteTissu = (tissu) => {
    setTissuToDelete(tissu);
    setShowDeleteConfirm(true);
  };

  const confirmDeleteTissu = async () => {
    if (!tissuToDelete?._id) return;

    try {
      await apiRequest(`/api/tissus/${tissuToDelete._id}`, { method: 'DELETE' });
      setShowDeleteConfirm(false);
      setTissuToDelete(null);
      loadTissus();
    } catch (err) {
      setError(err.message);
    }
  };

  const openEditModal = (tissu) => {
    setEditingTissuId(tissu._id);
    setEditForm({
      nom: tissu.nom || '',
      description: tissu.description || '',
      genre: tissu.genre || 'unisexe',
      type: tissu.type || '',
      prix: tissu.prix || '',
      prix_fournisseur: tissu.prix_fournisseur || '',
      couleur: tissu.couleur || '#d4af37',
      currentImageUrl: getTissuImageUrl(tissu),
    });
    setEditImageFile(null);
    setShowEditModal(true);
  };

  const updateTissu = async (event) => {
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
        type: editForm.type,
        prix: Number(editForm.prix),
        prix_fournisseur: Number(editForm.prix_fournisseur) || 0,
        couleur: editForm.couleur,
      };

      if (images) payload.images = images;

      await apiRequest(`/api/tissus/${editingTissuId}`, {
        method: 'PUT',
        body: JSON.stringify(payload),
      });

      setShowEditModal(false);
      setEditingTissuId('');
      setEditImageFile(null);
      loadTissus();
    } catch (err) {
      setError(err.message);
    }
  };

  const createTissu = async (event) => {
    event.preventDefault();

    try {
      let images = [];
      if (imageFile) {
        const upload = await uploadSingleImage(imageFile);
        if (upload?.image?.url) {
          images = [{ url: upload.image.url, alt: form.nom }];
        }
      }

      await apiRequest('/api/tissus', {
        method: 'POST',
        body: JSON.stringify({
          nom: form.nom,
          description: form.description,
          genre: form.genre,
          type: form.type,
          prix: Number(form.prix),
          prix_fournisseur: Number(form.prix_fournisseur) || 0,
          couleur: form.couleur,
          images,
        }),
      });

      setForm(emptyForm);
      setImageFile(null);
      setShowCreateModal(false);
      loadTissus();
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

          <h1 className="page-title">Gestion des tissus</h1>
          <p className="subtitle">{filtered.length} tissus (actifs + inactifs)</p>

          <div className="toolbar">
            <button className="create-modele-btn" onClick={() => setShowCreateModal(true)}>
              <span aria-hidden="true">＋</span> Créer un nouveau tissu
            </button>
          </div>

          <div className="panel row search">
            <input placeholder="Rechercher un tissu..." value={search} onChange={(e) => setSearch(e.target.value)} />
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
                  <th>Type</th>
                  <th>Couleur</th>
                  <th>Prix</th>
                  <th>Prix fournisseur</th>
                  <th>Statut</th>
                  <th>Activation</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((tissu) => (
                  <tr key={tissu._id}>
                    <td>
                      {getTissuImageUrl(tissu) ? (
                        <img className="modele-thumb" src={getTissuImageUrl(tissu)} alt={tissu.nom} />
                      ) : (
                        <span className="thumb-placeholder">Aucune</span>
                      )}
                    </td>
                    <td>{tissu.nom}</td>
                    <td>{tissu.genre}</td>
                    <td>{tissu.type || 'standard'}</td>
                    <td>
                      <div className="color-chip-wrap">
                        <span className="color-dot" style={{ backgroundColor: tissu.couleur || '#d4af37' }} />
                        <span>{tissu.couleur || '-'}</span>
                      </div>
                    </td>
                    <td>{tissu.prix} FCFA</td>
                    <td>{tissu.prix_fournisseur || 0} FCFA</td>
                    <td>
                      <span className={`pill ${tissu.actif ? 'success' : 'muted'}`}>{tissu.actif ? 'Actif' : 'Inactif'}</span>
                    </td>
                    <td>
                      <label className="switch">
                        <input type="checkbox" checked={!!tissu.actif} onChange={() => toggleActif(tissu)} />
                        <span className="slider" />
                      </label>
                    </td>
                    <td className="table-actions-cell">
                      <div className="actions">
                        <button className="info icon-only" onClick={() => openEditModal(tissu)} title="Modifier" aria-label="Modifier">
                          <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">
                            <path d="M3 17.25V21h3.75l11-11-3.75-3.75-11 11z" />
                            <path d="M20.71 7.04a1 1 0 0 0 0-1.41L18.37 3.3a1 1 0 0 0-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.84z" />
                          </svg>
                        </button>
                        <button className="danger icon-only" onClick={() => askDeleteTissu(tissu)} title="Supprimer" aria-label="Supprimer">
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
                  Voulez-vous vraiment supprimer le tissu <strong>{tissuToDelete?.nom || 'sélectionné'}</strong> ?
                </p>
                <div className="actions" style={{ marginTop: 12 }}>
                  <button type="button" className="danger" onClick={confirmDeleteTissu}>Supprimer</button>
                  <button type="button" className="secondary" onClick={() => setShowDeleteConfirm(false)}>Annuler</button>
                </div>
              </div>
            </div>
          ) : null}

          {showEditModal ? (
            <div className="modal-overlay" onClick={() => setShowEditModal(false)}>
              <div className="modal-card" onClick={(event) => event.stopPropagation()}>
                <h3>Modifier le tissu</h3>
                <form className="row" onSubmit={updateTissu}>
                  <div className="row search">
                    <input
                      placeholder="Nom du tissu"
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
                      placeholder="Prix fournisseur"
                      value={editForm.prix_fournisseur}
                      onChange={(e) => setEditForm({ ...editForm, prix_fournisseur: e.target.value })}
                      required
                    />
                    <div />
                  </div>
                  <div className="row search">
                    <select value={editForm.genre} onChange={(e) => setEditForm({ ...editForm, genre: e.target.value })}>
                      <option value="homme">Homme</option>
                      <option value="femme">Femme</option>
                      <option value="unisexe">Unisexe</option>
                    </select>
                    <input
                      placeholder="Type (ex: bazin, coton)"
                      value={editForm.type}
                      onChange={(e) => setEditForm({ ...editForm, type: e.target.value })}
                    />
                  </div>
                  <div className="row search">
                    <input type="color" value={editForm.couleur || '#d4af37'} onChange={(e) => setEditForm({ ...editForm, couleur: e.target.value })} />
                    <div />
                  </div>
                  <div className="row search">
                    <input type="file" accept="image/*" onChange={(e) => setEditImageFile(e.target.files?.[0] || null)} />
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
                <h3>Créer un nouveau tissu</h3>
                <form className="row" onSubmit={createTissu}>
                  <div className="row search">
                    <input
                      value={form.nom}
                      onChange={(e) => setForm({ ...form, nom: e.target.value })}
                      placeholder="Nom"
                      required
                    />
                    <input
                      type="number"
                      value={form.prix}
                      onChange={(e) => setForm({ ...form, prix: e.target.value })}
                      placeholder="Prix"
                      required
                    />
                  </div>
                  <div className="row search">
                    <input
                      type="number"
                      placeholder="Prix fournisseur"
                      value={form.prix_fournisseur}
                      onChange={(e) => setForm({ ...form, prix_fournisseur: e.target.value })}
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
                    <input
                      placeholder="Type (ex: bazin, coton)"
                      value={form.type}
                      onChange={(e) => setForm({ ...form, type: e.target.value })}
                    />
                  </div>
                  <div className="row search">
                    <input type="color" value={form.couleur || '#d4af37'} onChange={(e) => setForm({ ...form, couleur: e.target.value })} />
                    <input type="file" accept="image/*" onChange={(e) => setImageFile(e.target.files?.[0] || null)} />
                  </div>
                  <textarea
                    value={form.description}
                    onChange={(e) => setForm({ ...form, description: e.target.value })}
                    placeholder="Description"
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
