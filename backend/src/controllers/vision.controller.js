const CV_SERVICE_URL = process.env.CV_SERVICE_URL || 'http://cv-service:8000';

async function proxyToCv(path, body) {
  const response = await fetch(`${CV_SERVICE_URL}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(data.detail || data.error || 'Erreur service vision');
  }
  return data;
}

exports.startVisionSession = async (req, res) => {
  try {
    const data = await proxyToCv('/session/start', req.body);
    res.json(data);
  } catch (error) {
    res.status(502).json({ error: error.message });
  }
};

exports.analyzeVisionFrame = async (req, res) => {
  try {
    const { session_id } = req.params;
    const data = await proxyToCv(`/session/${session_id}/analyze`, req.body);
    res.json(data);
  } catch (error) {
    res.status(502).json({ error: error.message });
  }
};

exports.getVisionSession = async (req, res) => {
  try {
    const { session_id } = req.params;
    const response = await fetch(`${CV_SERVICE_URL}/session/${session_id}`);
    const data = await response.json().catch(() => ({}));

    if (!response.ok) {
      return res
        .status(response.status)
        .json({ error: data.detail || 'Session vision introuvable' });
    }

    res.json(data);
  } catch (error) {
    res.status(502).json({ error: error.message });
  }
};
