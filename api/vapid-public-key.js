module.exports = function handler(req, res) {
  const key = process.env.VAPID_PUBLIC_KEY;
  if (!key) return res.status(503).json({ error: 'not_configured' });
  res.setHeader('Cache-Control', 'public, max-age=86400');
  return res.status(200).json({ key });
};
