{{flutter_js}}
{{flutter_build_config}}

// Use HTML renderer so the browser handles text natively —
// correct emoji rendering, system font fallbacks, no CanvasKit overhead.
_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    let appRunner = await engineInitializer.initializeEngine({
      renderer: "html",
    });
    await appRunner.runApp();
  }
});
