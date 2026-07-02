const webpush = require('web-push');
const { createClient } = require('@supabase/supabase-js');

const VAPID_PUBLIC  = process.env.VAPID_PUBLIC_KEY;
const VAPID_PRIVATE = process.env.VAPID_PRIVATE_KEY;
const VAPID_SUBJECT = process.env.VAPID_SUBJECT ?? 'mailto:noreply@example.com';
const SB_URL        = process.env.SUPABASE_URL;
const SB_SERVICE    = process.env.SUPABASE_SERVICE_ROLE_KEY;
const CRON_SECRET   = process.env.CRON_SECRET;

// JST日付文字列からUTC時(2-12)を決定論的に計算 = JST 11:00-21:00
function designatedHourUtc(dateStr) {
  let h = 0;
  for (const c of dateStr) h = (h * 31 + c.charCodeAt(0)) >>> 0;
  return (h % 11) + 2;
}

module.exports = async function handler(req, res) {
  if (CRON_SECRET && req.headers.authorization !== `Bearer ${CRON_SECRET}`) {
    return res.status(401).json({ error: 'unauthorized' });
  }
  if (!VAPID_PUBLIC || !VAPID_PRIVATE) {
    return res.status(500).json({ error: 'VAPID keys not configured' });
  }
  if (!SB_URL || !SB_SERVICE) {
    return res.status(500).json({ error: 'Supabase service key not configured' });
  }

  const nowJst  = new Date(Date.now() + 9 * 3600e3);
  const today   = nowJst.toISOString().slice(0, 10);
  const nowUtcH = new Date().getUTCHours();
  const targetH = designatedHourUtc(today);

  if (nowUtcH !== targetH) {
    return res.status(200).json({ skipped: true, target: targetH, current: nowUtcH });
  }

  webpush.setVapidDetails(VAPID_SUBJECT, VAPID_PUBLIC, VAPID_PRIVATE);

  const sb = createClient(SB_URL, SB_SERVICE);
  const { data: subs, error } = await sb.from('push_subscriptions').select('id, endpoint, p256dh, auth').eq('is_active', true);
  if (error) return res.status(500).json({ error: error.message });

  const payload = JSON.stringify({
    title: 'コエリアル',
    body:  'いまの声を残そう。今日1回だけの記録を。',
    url:   '/',
  });

  let sent = 0, failed = 0;
  const expired = [];

  await Promise.allSettled((subs ?? []).map(async (sub) => {
    try {
      await webpush.sendNotification(
        { endpoint: sub.endpoint, keys: { p256dh: sub.p256dh, auth: sub.auth } },
        payload,
        { TTL: 7200 }
      );
      sent++;
    } catch (err) {
      if (err.statusCode === 410 || err.statusCode === 404) expired.push(sub.id);
      failed++;
    }
  }));

  if (expired.length) {
    await sb.from('push_subscriptions').delete().in('id', expired);
  }

  return res.status(200).json({ sent, failed, expired: expired.length, date: today });
};
