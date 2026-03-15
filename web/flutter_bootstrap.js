{
  {
    flutter_js;
  }
}
{
  {
    flutter_build_config;
  }
}

// Use CanvasKit renderer for consistent cross-browser rendering.
// HTML renderer hangs on complex layouts in Safari (WebKit).
// The Safari WebGL2 shim in index.html makes CanvasKit fall back to
// WebGL1 on WebKit, which is the stable rendering path there.
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    let appRunner = await engineInitializer.initializeEngine({
      renderer: "canvaskit",
    });
    await appRunner.runApp();
  },
});
