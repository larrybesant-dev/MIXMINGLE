{{flutter_js}}
{{flutter_build_config}}

// Skip the Flutter service worker wait entirely.
// Passing ANY serviceWorkerSettings object — even with serviceWorkerVersion:null —
// causes Flutter's loader to call prepareServiceWorker() and block for up to 4 s.
// Omitting the key entirely is the only way to bypass the wait completely.
// PWA offline caching is not required for a live-streaming app; the Firebase
// push-messaging worker (firebase-messaging-sw.js) is still registered
// independently in index.html and is unaffected by this change.
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    let appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
  },
});
