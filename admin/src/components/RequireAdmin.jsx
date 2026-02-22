'use client';

import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';

export default function RequireAdmin({ children }) {
  const router = useRouter();
  const [ready, setReady] = useState(false);

  useEffect(() => {
    const token = localStorage.getItem('adminToken');
    if (!token) {
      router.replace('/admin/login');
      return;
    }
    setReady(true);
  }, [router]);

  if (!ready) {
    return <main className="container">Chargement...</main>;
  }

  return children;
}
