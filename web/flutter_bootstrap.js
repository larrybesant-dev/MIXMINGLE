{{flutter_js}}
{{flutter_build_config}}

// Skip the Flutter service worker wait entirely.
// The default bootstrap waits up to 4 s for flutter_service_worker.js to
// activate before the Flutter engine starts — this directly blocks Agora WASM
// initialization and causes the init-attempt-1 timeout seen in the logs.
// PWA offline caching is not required for a live-streaming app; the Firebase
// push-messaging worker (firebase-messaging-sw.js) is still registered
// independently in index.html and is unaffected by this change.
_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: null,
  },
  onEntrypointLoaded: async function (engineInitializer) {
    let appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
  },
});
