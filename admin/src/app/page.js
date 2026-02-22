import Link from 'next/link';

export default function Home() {
  return (
    <main className="container">
      <h1>Administration Kala</h1>
      <p>Interface de gestion des modèles, tissus et commandes.</p>
      <Link href="/admin">Accéder au back-office</Link>
    </main>
  );
}
