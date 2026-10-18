{{flutter_js}}
{{flutter_build_config}}

// Cargar CanvasKit desde el propio sitio para permitir uso offline.
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: new URL('canvaskit/', document.baseURI).href,
  },
});
