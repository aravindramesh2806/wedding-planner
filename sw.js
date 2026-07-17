// Kill-switch service worker: unregisters the old cached PWA and reloads clients.
self.addEventListener('install', e => { self.skipWaiting(); });
self.addEventListener('activate', e => {
  e.waitUntil((async () => {
    try {
      const ks = await caches.keys();
      await Promise.all(ks.map(k => caches.delete(k)));
      await self.registration.unregister();
      const cs = await self.clients.matchAll({ type: 'window' });
      cs.forEach(c => c.navigate(c.url));
    } catch (e) {}
  })());
});

