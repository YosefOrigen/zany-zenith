const CACHE_NAME = 'yosef-inventario-v1';
const APP_SHELL = [
  '/yosef/admin/',
  '/yosef-admin.webmanifest',
  '/yosef-admin-icon.svg',
  '/yosef-admin-192.png',
  '/yosef-admin-512.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL)));
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((names) =>
      Promise.all(names.filter((name) => name !== CACHE_NAME).map((name) => caches.delete(name))),
    ),
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const requestUrl = new URL(event.request.url);
  if (event.request.method !== 'GET' || requestUrl.origin !== self.location.origin) return;

  if (event.request.mode === 'navigate' && requestUrl.pathname.startsWith('/yosef/admin')) {
    event.respondWith(
      fetch(event.request).catch(async () => {
        const cache = await caches.open(CACHE_NAME);
        return (await cache.match('/yosef/admin/')) || Response.error();
      }),
    );
  }
});
