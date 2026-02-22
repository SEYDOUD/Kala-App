'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { loginAdmin } from '@/lib/api';

export default function AdminLoginPage() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const router = useRouter();

  const handleSubmit = async (event) => {
    event.preventDefault();
    setError('');

    try {
      const data = await loginAdmin(username, password);
      const isAdmin = data.userType === 'admin' || data.user?.type_utilisateur === 'admin';
      if (!isAdmin) {
        throw new Error('Ce compte n\'est pas administrateur.');
      }

      localStorage.setItem('adminToken', data.token);
      localStorage.setItem('adminProfile', JSON.stringify(data.user));
      router.push('/admin');
    } catch (err) {
      setError(err.message);
    }
  };

  return (
    <main className="login-shell">
      <section className="login-wrap">
        <aside className="login-aside">
          <div className="brand-logo">✂</div>
          <h2>KALA Admin</h2>
          <p>Accède au back-office pour gérer les modèles, tissus et commandes avec une interface claire et rapide.</p>
          <div className="login-aside-foot">Espace sécurisé • Administrateurs uniquement</div>
        </aside>

        <div className="login-card">
          <span className="pill">Connexion sécurisée</span>
          <h1 className="page-title">Bon retour 👋</h1>
          <p className="subtitle">Entre tes identifiants pour continuer.</p>

          <form className="login-form" onSubmit={handleSubmit}>
            <div className="field-group">
              <label className="field-label" htmlFor="username">Nom d'utilisateur</label>
              <input
                id="username"
                placeholder="admin_kala"
                value={username}
                onChange={(event) => setUsername(event.target.value)}
              />
            </div>

            <div className="field-group">
              <label className="field-label" htmlFor="password">Mot de passe</label>
              <input
                id="password"
                type="password"
                placeholder="••••••••"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
              />
            </div>

            <button type="submit" className="login-submit">Se connecter</button>
            {error ? <p className="error-text">{error}</p> : null}
          </form>
        </div>
      </section>
    </main>
  );
}
