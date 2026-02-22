'use client';

import { useEffect, useMemo, useState } from 'react';
import NavBar from '@/components/NavBar';
import RequireAdmin from '@/components/RequireAdmin';
import { apiRequest } from '@/lib/api';

export default function ModelesPage() {
  const [modeles, setModeles] = useState([]);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [genre, setGenre] = useState('');

  const dateText = useMemo(
    () => new Date().toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }),
    []
  );

  const loadModeles = async () => {
    try {
      const data = await apiRequest('/api/modeles?limit=100');
      setModeles(data.modeles || []);
      setError('');
    } catch (err) {
      setError(err.message);
    }
  };

  useEffect(() => {
    loadModeles();
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

  const deleteModele = async (id) => {
    await apiRequest(`/api/modeles/${id}`, { method: 'DELETE' });
    loadModeles();
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
          <p className="subtitle">{filtered.length} modèles au catalogue</p>

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
                  <th>Nom</th>
                  <th>Genre</th>
                  <th>Prix</th>
                  <th>Statut</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((modele) => (
                  <tr key={modele._id}>
                    <td>{modele.nom}</td>
                    <td>{modele.genre}</td>
                    <td>{modele.prix} FCFA</td>
                    <td>
                      <span className={`pill ${modele.actif ? 'success' : 'muted'}`}>{modele.actif ? 'Actif' : 'Inactif'}</span>
                    </td>
                    <td className="actions">
                      <button className="secondary" onClick={() => toggleActif(modele)}>
                        {modele.actif ? 'Désactiver' : 'Activer'}
                      </button>
                      <button className="danger" onClick={() => deleteModele(modele._id)}>Supprimer</button>
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
