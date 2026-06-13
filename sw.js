// コエリアル Service Worker
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (e) => e.waitUntil(self.clients.claim()));
self.addEventListener('fetch', () => {});

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
  const url = e.notification.data?.url ?? '/';
  e.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((cs) => {
      const open = cs.find((c) => c.url.startsWith(self.location.origin));
      return open ? open.focus() : clients.openWindow(url);
    })
  );
});
