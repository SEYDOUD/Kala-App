const API_URL = (process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000').replace(/\/$/, '');

export async function apiRequest(path, options = {}) {
  const token = typeof window !== 'undefined' ? localStorage.getItem('adminToken') : null;

  let response;

  try {
    response = await fetch(`${API_URL}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(options.headers || {}),
    },
    cache: 'no-store',
    });
  } catch (error) {
    throw new Error(`Impossible de joindre l'API (${API_URL}). Vérifie que le backend tourne et que NEXT_PUBLIC_API_URL est correct.`);
  }

  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(data.error || 'Erreur API');
  }

  return data;
}

export async function loginAdmin(username, password) {
  return apiRequest('/api/auth/login', {
    method: 'POST',
    body: JSON.stringify({ username, password }),
  });
}

export async function uploadSingleImage(file) {
  const token = typeof window !== 'undefined' ? localStorage.getItem('adminToken') : null;
  const formData = new FormData();
  formData.append('image', file);

  const response = await fetch(`${API_URL}/api/upload/single`, {
    method: 'POST',
    headers: {
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: formData,
  });

  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(data.error || 'Erreur upload image');
  }

  return data;
}

export async function uploadSingleVideo(file) {
  const token = typeof window !== 'undefined' ? localStorage.getItem('adminToken') : null;
  const formData = new FormData();
  formData.append('video', file);

  const response = await fetch(`${API_URL}/api/upload/video`, {
    method: 'POST',
    headers: {
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: formData,
  });

  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(data.error || 'Erreur upload video');
  }

  return data;
}
