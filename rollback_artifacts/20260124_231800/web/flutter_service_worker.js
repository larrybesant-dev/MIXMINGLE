"use strict";
const MANIFEST = "flutter-app-manifest";
const TEMP = "flutter-temp-cache";
const CACHE_NAME = "flutter-app-cache";

const RESOURCES = {
  "assets/AssetManifest.bin": "a35050b63b2657769ff3883231c73bfa",
  "assets/AssetManifest.bin.json": "8c8bd9cc2f29d826b1e36afdd04bcf89",
  "assets/assets/images/default_avatar.png": "a64b6f6fa163c329ddfea0e09acc1f94",
  "assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
  "assets/fonts/MaterialIcons-Regular.otf": "2932e31c540bff5ed1e9cf552791a341",
  "assets/NOTICES": "77650541eab942537333239042f38b70",
  "assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
  "assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
  "assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
  "canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
  "canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
  "canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
  "canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
  "canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
  "canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
  "canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
  "canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
  "canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
  "canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
  "canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
  "canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
  "favicon.png": "5dcef449791fa27946b3d35ad8803796",
  "firebase-messaging-sw.js": "f1600f5765cb797c27faeb6472de58a0",
  "flutter.js": "24bc71911b75b5f8135c949e27a2984e",
  "flutter_bootstrap.js": "dd91f9ff6f9a0d6f209ada596f35dc4b",
  "hms-bundle.iife.js": "3d889b8e11a3e58c6d19ec5f5eecb73e",
  "icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
  "icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
  "icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
  "icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
  "index.html": "61de48bdb41f93e3eba79989338c22a9",
  "/": "61de48bdb41f93e3eba79989338c22a9",
  "login.html": "f0e0e64956a65ef4562a5d3e717acd71",
  "main.dart.js": "e7a834faa0367d42a8f7d9d71be873c8",
  "main.dart.js_1.part.js": "4ba855e7fe9d4ef594de6fee5e585114",
  "main.dart.js_10.part.js": "60aa768702a28ebb892fd9815d7d51b0",
  "main.dart.js_11.part.js": "17191a905243c21ac56411d84807185c",
  "main.dart.js_12.part.js": "e18f89508889d2a3aa35d5978668fc8f",
  "main.dart.js_13.part.js": "2df05084915c08c8b90f9711d1b7f724",
  "main.dart.js_14.part.js": "eaf42da3d7380ded001d3256d0c0e8e0",
  "main.dart.js_15.part.js": "55eadec1f5ff8ea16a9213d45e95a334",
  "main.dart.js_16.part.js": "9f5f8209287ddc013033c1b0a324d57c",
  "main.dart.js_18.part.js": "6135e4fe2f74da3a1a20920119bf1225",
  "main.dart.js_19.part.js": "83e34d0a8e8439ef315cb7de081a2afa",
  "main.dart.js_20.part.js": "cd8b1e38e89ad55c95a7ee2b8e7052bc",
  "main.dart.js_3.part.js": "203c9804abb9a7ea04cddf04ee3ff5c7",
  "main.dart.js_4.part.js": "5344b855cc5dbae1912b9f87d10bf0d5",
  "main.dart.js_5.part.js": "34f71335bc7119c800c00d2a55e01e86",
  "main.dart.js_6.part.js": "48c3c53dd0b029aea5dd93bd9991981a",
  "main.dart.js_7.part.js": "fefb307e5da459d9396a673384030704",
  "main.dart.js_9.part.js": "0dbf8fce8d8db534a7a2375ecd6380f6",
  "manifest.json": "53151a9131c38b70de8d3c6315b68d81",
  "privacy.html": "89a79cf4cb4628defe8db603616a4590",
  "profile.html": "0ca389d643e2823e58604d687b4ec6e4",
  "room.html": "18025bfcceaf4d9e05b99c7b69229600",
  "settings.html": "21044703a116029421b399f4cc07db41",
  "set_debug_token.html": "9738ada83bf5b022990af66685c61eb4",
  "signin.html": "d41d8cd98f00b204e9800998ecf8427e",
  "signup.html": "d41d8cd98f00b204e9800998ecf8427e",
  "terms.html": "065e4eb9afe0122f5a431734c176f034",
  "version.json": "d5e0d2c4cc5c5dfa3138b2c53c9fbdc1",
};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = [
  "main.dart.js",
  "index.html",
  "flutter_bootstrap.js",
  "assets/AssetManifest.bin.json",
  "assets/FontManifest.json",
];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(CORE.map((value) => new Request(value, { cache: "reload" })));
    }),
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function (event) {
  return event.waitUntil(
    (async function () {
      try {
        var contentCache = await caches.open(CACHE_NAME);
        var tempCache = await caches.open(TEMP);
        var manifestCache = await caches.open(MANIFEST);
        var manifest = await manifestCache.match("manifest");
        // When there is no prior manifest, clear the entire cache.
        if (!manifest) {
          await caches.delete(CACHE_NAME);
          contentCache = await caches.open(CACHE_NAME);
          for (var request of await tempCache.keys()) {
            var response = await tempCache.match(request);
            await contentCache.put(request, response);
          }
          await caches.delete(TEMP);
          // Save the manifest to make future upgrades efficient.
          await manifestCache.put("manifest", new Response(JSON.stringify(RESOURCES)));
          // Claim client to enable caching on first launch
          self.clients.claim();
          return;
        }
        var oldManifest = await manifest.json();
        var origin = self.location.origin;
        for (var request of await contentCache.keys()) {
          var key = request.url.substring(origin.length + 1);
          if (key == "") {
            key = "/";
          }
          // If a resource from the old manifest is not in the new cache, or if
          // the MD5 sum has changed, delete it. Otherwise the resource is left
          // in the cache and can be reused by the new service worker.
          if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
            await contentCache.delete(request);
          }
        }
        // Populate the cache with the app shell TEMP files, potentially overwriting
        // cache files preserved above.
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put("manifest", new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      } catch (err) {
        // On an unhandled exception the state of the cache cannot be guaranteed.
        console.error("Failed to upgrade service worker: " + err);
        await caches.delete(CACHE_NAME);
        await caches.delete(TEMP);
        await caches.delete(MANIFEST);
      }
    })(),
  );
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== "GET") {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf("?v=") != -1) {
    key = key.split("?v=")[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + "/#") || key == "") {
    key = "/";
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == "/") {
    return onlineFirst(event);
  }
  event.respondWith(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return (
          response ||
          fetch(event.request).then((response) => {
            if (response && Boolean(response.ok)) {
              cache.put(event.request, response.clone());
            }
            return response;
          })
        );
      });
    }),
  );
});
self.addEventListener("message", (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === "skipWaiting") {
    self.skipWaiting();
    return;
  }
  if (event.data === "downloadOffline") {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request)
      .then((response) => {
        return caches.open(CACHE_NAME).then((cache) => {
          cache.put(event.request, response.clone());
          return response;
        });
      })
      .catch((error) => {
        return caches.open(CACHE_NAME).then((cache) => {
          return cache.match(event.request).then((response) => {
            if (response != null) {
              return response;
            }
            throw error;
          });
        });
      }),
  );
}
