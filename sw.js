// Wedding Planner service worker.
// CACHE is auto-bumped on every deploy by deploy.sh — do not rely on editing it by hand.
// Strategy: network-first. HTML/JS navigations bypass the browser HTTP cache so a fresh
// deploy shows immediately; other assets use the HTTP cache and fall back to the SW cache
// only when offline. On activate, stale caches from older versions are deleted.
const CACHE = 'wp-20260627-125649';

self.addEventListener('install', e => { self.skipWaiting(); });

self.addEventListener('activate', e => {
  e.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)));
    await self.clients.claim();
  })());
});

// ---- Web Push ----
self.addEventListener('push', e => {
  let d = {};
  try { d = e.data ? e.data.json() : {}; } catch (_) { try { d = { body: e.data.text() }; } catch (_) {} }
  const title = d.title || 'Wedding update';
  e.waitUntil(self.registration.showNotification(title, {
    body: d.body || '',
    icon: 'icon-512.png',
    badge: 'icon-512.png',
    data: { url: d.url || './' },
    tag: 'wp-alert'
  }));
});

self.addEventListener('notificationclick', e => {
  e.notification.close();
  const url = (e.notification.data && e.notification.data.url) || './';
  e.waitUntil((async () => {
    const all = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
    for (const c of all) {
      if ('focus' in c) { try { await c.navigate(url); } catch (_) {} return c.focus(); }
    }
    return self.clients.openWindow(url);
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
