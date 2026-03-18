'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { usePathname, useRouter, useSearchParams } from 'next/navigation';

const icons = {
  dashboard: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <rect x="3" y="3" width="8" height="8" rx="2" fill="currentColor" />
      <rect x="13" y="3" width="8" height="5" rx="2" fill="currentColor" />
      <rect x="13" y="10" width="8" height="11" rx="2" fill="currentColor" />
      <rect x="3" y="13" width="8" height="8" rx="2" fill="currentColor" />
    </svg>
  ),
  finance: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <rect x="3" y="6" width="18" height="12" rx="3" fill="currentColor" />
      <rect x="6" y="9" width="6" height="2" rx="1" fill="#fff" />
      <circle cx="17" cy="12" r="3" fill="#fff" />
    </svg>
  ),
  ops: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <rect x="4" y="3" width="16" height="18" rx="2" fill="currentColor" />
      <path d="M8 8l2 2 4-4" stroke="#fff" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round" />
      <rect x="8" y="13" width="8" height="2" rx="1" fill="#fff" />
    </svg>
  ),
  commandes: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M4 7h16l-2 12H6L4 7z" fill="currentColor" />
      <path d="M8 7l4-4 4 4" stroke="#fff" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  ),
  modeles: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M6 6l6 4 6-4" stroke="currentColor" strokeWidth="2" fill="none" strokeLinecap="round" />
      <path d="M12 10v8" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
      <path d="M6 20h12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
    </svg>
  ),
  tissus: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <rect x="3" y="5" width="18" height="14" rx="2" fill="currentColor" />
      <path d="M3 10h18" stroke="#fff" strokeWidth="2" />
      <path d="M3 14h18" stroke="#fff" strokeWidth="2" />
    </svg>
  ),
};

const links = [
  { href: '/admin', label: 'Pilotage', icon: icons.dashboard },
  {
    href: '/admin/finances',
    label: 'Finances',
    icon: icons.finance,
    sectionKey: 'finances',
    children: [
      { href: '/admin/finances?tab=transactions', label: 'Transactions', tab: 'transactions' },
      { href: '/admin/finances?tab=fournisseurs', label: 'Paiement fournisseurs', tab: 'fournisseurs' },
    ],
  },
  {
    href: '/admin/operations',
    label: 'Operations',
    icon: icons.ops,
    sectionKey: 'operations',
    children: [
      { href: '/admin/operations?tab=taches', label: 'Planification des taches', tab: 'taches' },
      { href: '/admin/operations?tab=campagnes', label: 'Campagnes', tab: 'campagnes' },
    ],
  },
  {
    href: '/admin/commandes',
    label: 'Commandes',
    icon: icons.commandes,
    sectionKey: 'commandes',
    children: [
      { href: '/admin/commandes?tab=sur_mesure', label: 'Sur mesure', tab: 'sur_mesure' },
      { href: '/admin/commandes?tab=tissus', label: 'Commandes tissu', tab: 'tissus' },
      { href: '/admin/commandes?tab=pret_a_porter', label: 'Commande pret a porter', tab: 'pret_a_porter' },
    ],
  },
  { href: '/admin/modeles', label: 'Modeles', icon: icons.modeles },
  { href: '/admin/tissus', label: 'Tissus', icon: icons.tissus },
];

export default function NavBar() {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const router = useRouter();
  const tabParam = searchParams.get('tab');
  const [collapsed, setCollapsed] = useState(false);
  const [openSections, setOpenSections] = useState({
    finances: false,
    operations: false,
    commandes: false,
  });

  useEffect(() => {
    if (typeof window === 'undefined') return;
    const stored = window.localStorage.getItem('kala_sidebar_collapsed');
    if (stored === '1') {
      setCollapsed(true);
    }
  }, []);

  useEffect(() => {
    if (typeof document === 'undefined') return;
    document.documentElement.dataset.sidebar = collapsed ? 'collapsed' : 'expanded';
    if (typeof window !== 'undefined') {
      window.localStorage.setItem('kala_sidebar_collapsed', collapsed ? '1' : '0');
    }
  }, [collapsed]);

  useEffect(() => {
    setOpenSections((prev) => ({
      ...prev,
      finances: pathname.startsWith('/admin/finances') ? true : prev.finances,
      operations: pathname.startsWith('/admin/operations') ? true : prev.operations,
      commandes: pathname.startsWith('/admin/commandes') ? true : prev.commandes,
    }));
  }, [pathname]);

  const toggleSection = (sectionKey) => {
    setOpenSections((prev) => ({ ...prev, [sectionKey]: !prev[sectionKey] }));
  };

  const logout = () => {
    localStorage.removeItem('adminToken');
    localStorage.removeItem('adminProfile');
    router.push('/admin/login');
  };

  return (
    <aside className={`sidebar ${collapsed ? 'collapsed' : ''}`}>
      <div className="brand">
        <div className="brand-logo">K</div>
        <div className="brand-name">KALA</div>
        <button
          type="button"
          className="sidebar-toggle"
          onClick={() => setCollapsed((prev) => !prev)}
          aria-label={collapsed ? 'Ouvrir le menu' : 'Reduire le menu'}
        >
          <span />
        </button>
      </div>

      <nav className="side-nav">
        {links.map((link) => {
          const isChildActive =
            link.children?.some((child) => pathname === link.href && tabParam === child.tab) || false;
          const isActive = pathname === link.href || isChildActive;
          const isOpen = link.sectionKey ? openSections[link.sectionKey] : false;

          return (
            <div key={link.href} className="side-group">
              {link.children ? (
                <button
                  type="button"
                  className={`side-link ${isActive ? 'active' : ''}`}
                  onClick={() => toggleSection(link.sectionKey)}
                  data-label={link.label}
                >
                  <span className="side-icon">{link.icon}</span>
                  <span>{link.label}</span>
                  <span className={`side-caret ${isOpen ? 'open' : ''}`} />
                </button>
              ) : (
                <Link href={link.href} className={`side-link ${isActive ? 'active' : ''}`} data-label={link.label}>
                  <span className="side-icon">{link.icon}</span>
                  <span>{link.label}</span>
                </Link>
              )}
              {link.children && isOpen ? (
                <div className="side-subnav">
                  {link.children.map((child) => {
                    const childActive = pathname === link.href && tabParam === child.tab;
                    return (
                      <Link
                        key={child.href}
                        href={child.href}
                        className={`side-sublink ${childActive ? 'active' : ''}`}
                        data-label={child.label}
                      >
                        <span className="sub-dot" />
                        <span>{child.label}</span>
                      </Link>
                    );
                  })}
                </div>
              ) : null}
            </div>
          );
        })}
      </nav>

      <div className="sidebar-footer">
        <h4>Kala Admin</h4>
        <p>Administrateur</p>
        <button className="logout-btn" onClick={logout}>Deconnexion</button>
      </div>
    </aside>
  );
}
