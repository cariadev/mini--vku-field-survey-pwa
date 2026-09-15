'use strict';

const CACHE_NAME = 'vku-survey-cache-v2';

// Cập nhật đường dẫn chuẩn xác cho Flutter Web
const RESOURCES = [
  '/',
  './',
  'index.html',
  './index.html',
  'flutter_bootstrap.js',
  'main.dart.js',
  'manifest.json',
  'favicon.png',
  'assets/FontManifest.json',
  'assets/AssetManifest.json',
  'assets/AssetManifest.bin'
];

// 1. Khi Install: Caching App Shell
self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('[SW] Caching App Shell...');
      // Sử dụng map để tránh việc 1 file lỗi làm thất bại toàn bộ cache
      return Promise.all(
        RESOURCES.map((url) => {
          return cache.add(url).catch((err) => {
            console.warn('[SW] Caching skipped for:', url, err);
          });
        })
      );
    })
  );
});

// 2. Khi Activate: Dọn dẹp Cache cũ
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME) {
            console.log('[SW] Deleting old cache:', key);
            return caches.delete(key);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

// 3. Xử lý Fetch: Chế độ Cache-First mạnh mẽ
self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;

  event.respondWith(
    caches.match(event.request, { ignoreSearch: true }).then((cachedResponse) => {
      if (cachedResponse) {
        return cachedResponse;
      }

      return fetch(event.request)
        .then((networkResponse) => {
          if (
            networkResponse &&
            networkResponse.status === 200 &&
            (networkResponse.type === 'basic' || networkResponse.type === 'cors')
          ) {
            const responseToCache = networkResponse.clone();
            caches.open(CACHE_NAME).then((cache) => {
              cache.put(event.request, responseToCache);
            });
          }
          return networkResponse;
        })
        .catch(() => {
          // Xử lý khi mất mạng hoàn toàn và truy cập trang chính
          if (event.request.mode === 'navigate') {
            return caches.match('./index.html') || caches.match('index.html') || caches.match('/');
          }
        });
    })
  );
});