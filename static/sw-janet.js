var CACHE = "janet-v3";
var FILES = [
	"/janet",
	"/janet/",
	"/janet/all.ca5b30588c0206a6.js",
	"/fonts/IBMPlexMono-Regular.otf",
];

self.addEventListener("install", function (e) {
	e.waitUntil(
		Promise.all([
			caches.open(CACHE).then(function (c) {
				return c.addAll(FILES);
			}),
			self.skipWaiting(),
		]),
	);
});

self.addEventListener("activate", function (e) {
	e.waitUntil(
		caches
			.keys()
			.then(function (keys) {
				return Promise.all(
					keys
						.filter(function (k) {
							return k !== CACHE;
						})
						.map(function (k) {
							return caches.delete(k);
						}),
				);
			})
			.then(function () {
				return self.clients.claim();
			}),
	);
});

self.addEventListener("fetch", function (e) {
	e.respondWith(
		caches.match(e.request.url).then(function (cached) {
			return cached || fetch(e.request);
		}),
	);
});
