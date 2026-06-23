// Wedding Planner service worker.
// CACHE is auto-bumped on every deploy by deploy.sh — do not rely on editing it by hand.
// Strategy: network-first. HTML/JS navigations bypass the browser HTTP cache so a fresh
// deploy shows immediately; other assets use the HTTP cache and fall back to the SW cache
// only when offline. On activate, stale caches from older versions are deleted.
const CACHE = 'wp-20260623-195258';

self.addEventListener('install', e => { self.skipWaiting(); });

self.addEventListener('activate', e => {
  e.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)));
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return; // never touch Supabase POST RPCs

  let path = '';
  try { path = new URL(req.url).pathname; } catch (_) {}
  const isPage = req.mode === 'navigate' || path.endsWith('/') ||
                 /\.(html|js)$/i.test(path);

  if (isPage) {
    // Always fetch fresh from the network (skip HTTP cache) so deploys are picked up.
    e.respondWith(
      fetch(req, { cache: 'no-store' }).then(res => {
        try { const c = res.clone(); caches.open(CACHE).then(ch => ch.put(req, c)); } catch (_) {}
        return res;
      }).catch(() => caches.match(req))
    );
  } else {
    // Assets (icons, fonts, etc.): network-first, cache for offline.
    e.respondWith(
      fetch(req).then(res => {
        try { const c = res.clone(); caches.open(CACHE).then(ch => ch.put(req, c)); } catch (_) {}
        return res;
      }).catch(() => caches.match(req))
    );
  }
});
