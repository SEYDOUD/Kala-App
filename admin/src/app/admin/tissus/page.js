'use client';

import { useEffect, useMemo, useState } from 'react';
import NavBar from '@/components/NavBar';
import RequireAdmin from '@/components/RequireAdmin';
import { apiRequest } from '@/lib/api';

const emptyForm = { nom: '', description: '', genre: 'unisexe', prix: '', couleur: '' };

export default function TissusPage() {
  const [tissus, setTissus] = useState([]);
  const [form, setForm] = useState(emptyForm);
  const [error, setError] = useState('');

  const dateText = useMemo(
    () => new Date().toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }),
    []
  );

  const loadTissus = async () => {
    try {
      const data = await apiRequest('/api/tissus?limit=100');
      setTissus(data.tissus || []);
      setError('');
    } catch (err) {
      setError(err.message);
    }
  };

  useEffect(() => {
    loadTissus();
  }, []);

  const createTissu = async (event) => {
    event.preventDefault();
    await apiRequest('/api/tissus', { method: 'POST', body: JSON.stringify({ ...form, prix: Number(form.prix) }) });
    setForm(emptyForm);
    loadTissus();
  };

  const deleteTissu = async (id) => {
    await apiRequest(`/api/tissus/${id}`, { method: 'DELETE' });
    loadTissus();
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
          <p className="subtitle">{tissus.length} tissus disponibles</p>

          <form className="panel row" onSubmit={createTissu}>
            <input value={form.nom} onChange={(e) => setForm({ ...form, nom: e.target.value })} placeholder="Nom" required />
            <textarea value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} placeholder="Description" />
            <div className="row search">
              <select value={form.genre} onChange={(e) => setForm({ ...form, genre: e.target.value })}>
                <option value="homme">Homme</option>
                <option value="femme">Femme</option>
                <option value="unisexe">Unisexe</option>
              </select>
              <input type="number" value={form.prix} onChange={(e) => setForm({ ...form, prix: e.target.value })} placeholder="Prix" required />
            </div>
            <input value={form.couleur} onChange={(e) => setForm({ ...form, couleur: e.target.value })} placeholder="Couleur" />
            <button type="submit">Ajouter le tissu</button>
          </form>

          {error ? <p className="error-text">{error}</p> : null}

          <div className="panel table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>Nom</th>
                  <th>Genre</th>
                  <th>Couleur</th>
                  <th>Prix</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {tissus.map((tissu) => (
                  <tr key={tissu._id}>
                    <td>{tissu.nom}</td>
                    <td>{tissu.genre}</td>
                    <td>{tissu.couleur || '-'}</td>
                    <td>{tissu.prix} FCFA</td>
                    <td className="actions">
                      <button className="danger" onClick={() => deleteTissu(tissu._id)}>Supprimer</button>
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
