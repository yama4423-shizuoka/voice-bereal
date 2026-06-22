// コエリアル Service Worker
const SHELL_CACHE = 'shell-v2';
const CDN_CACHE = 'cdn-v1';

const SHELL_ASSETS = ['/', '/index.html', '/manifest.json', '/icon.svg'];

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(SHELL_CACHE).then((c) => c.addAll(SHELL_ASSETS))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (e) => {
  const keep = [SHELL_CACHE, CDN_CACHE];
  e.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => !keep.includes(k)).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (e) => {
  const { request } = e;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);

  // Supabase API とVercel関数はSWを通さない
  if (url.hostname.includes('supabase.co') ||
      url.pathname.startsWith('/api/') ||
      url.pathname.startsWith('/_vercel/')) return;

  // jsdelivr CDN: キャッシュファースト(supabase-jsなど)
  if (url.hostname === 'cdn.jsdelivr.net') {
    e.respondWith(
      caches.open(CDN_CACHE).then((c) =>
        c.match(request).then((cached) => {
          if (cached) return cached;
          return fetch(request).then((res) => {
            if (res.ok) c.put(request, res.clone());
            return res;
          });
        })
      )
    );
    return;
  }

  // 同一オリジンのシェル: ネットワークファースト -> キャッシュフォールバック
  if (url.origin === self.location.origin) {
    e.respondWith(
      fetch(request)
        .then((res) => {
          if (res.ok) {
            caches.open(SHELL_CACHE).then((c) => c.put(request, res.clone()));
          }
          return res;
        })
        .catch(() =>
          caches.match(request).then((cached) => cached ?? caches.match('/index.html'))
        )
    );
  }
});

self.addEventListener('push', (e) => {
  const data = e.data?.json() ?? {};
  e.waitUntil(
    self.registration.showNotification(data.title ?? 'コエリアル', {
      body: data.body ?? 'いまの声を残そう',
      icon: '/icon.svg',
      badge: '/icon.svg',
      data: { url: data.url ?? '/' },
    })
  );
});

self.addEventListener('notificationclick', (e) => {
  e.notification.close();
  const feedUrl = self.location.origin + '/?screen=feed';
  e.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((cs) => {
      const open = cs.find((c) => c.url.startsWith(self.location.origin));
      if (open) {
        open.postMessage({ type: 'SW_NAV', screen: 'screenFeed' });
        return open.focus();
      }
      return clients.openWindow(feedUrl);
    })
  );
});
