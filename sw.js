// コエリアル Service Worker(PWAインストール用の最小構成)
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (e) => e.waitUntil(self.clients.claim()));
self.addEventListener('fetch', () => { /* ネットワーク直結。キャッシュ戦略はROADMAP参照 */ });
