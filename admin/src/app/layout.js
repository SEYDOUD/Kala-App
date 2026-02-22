import './globals.css';

export const metadata = {
  title: 'Kala Admin',
  description: 'Back-office de gestion Kala',
};

export default function RootLayout({ children }) {
  return (
    <html lang="fr">
      <body>{children}</body>
    </html>
  );
}
