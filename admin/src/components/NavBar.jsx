'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';

const links = [
  { href: '/admin', label: 'Dashboard', icon: '📊' },
  { href: '/admin/modeles', label: 'Modèles', icon: '👔' },
  { href: '/admin/tissus', label: 'Tissus', icon: '🧵' },
  { href: '/admin/commandes', label: 'Commandes', icon: '📦' },
];

export default function NavBar() {
  const pathname = usePathname();
  const router = useRouter();

  const logout = () => {
    localStorage.removeItem('adminToken');
    localStorage.removeItem('adminProfile');
    router.push('/admin/login');
  };

  return (
    <aside className="sidebar">
      <div className="brand">
        <div className="brand-logo">✂</div>
        <div className="brand-name">KALA</div>
      </div>

      <nav className="side-nav">
        {links.map((link) => (
          <Link key={link.href} href={link.href} className={`side-link ${pathname === link.href ? 'active' : ''}`}>
            <span className="side-icon">{link.icon}</span>
            <span>{link.label}</span>
          </Link>
        ))}
      </nav>

      <div className="sidebar-footer">
        <h4>Kala Admin</h4>
        <p>Administrateur</p>
        <button className="logout-btn" onClick={logout}>↪ Déconnexion</button>
      </div>
    </aside>
  );
}
