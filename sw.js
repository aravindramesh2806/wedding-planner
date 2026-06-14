const CACHE = 'wp-v1';
self.addEventListener('install', e => { self.skipWaiting(); });
self.addEventListener('activate', e => { e.waitUntil(self.clients.claim()); });
self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return; // never touch Supabase POST RPCs
  e.respondWith(
    fetch(req).then(res => {
      try { const c = res.clone(); caches.open(CACHE).then(ch => ch.put(req, c)); } catch (_) {}
      return res;
    }).catch(() => caches.match(req))
  );
});
