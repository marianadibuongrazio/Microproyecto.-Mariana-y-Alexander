#!/usr/bin/env python3
"""Genera service worker de precache versionado sobre un build release Flutter.

Uso: python3 tool/build_pwa.py build/web
No requiere paquetes ni descarga dependencias.
"""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path


SW_NAME = "puzzle-sw.js"
PREFIX = "puzzle-unimet-"


def main() -> None:
    build = Path(sys.argv[1] if len(sys.argv) > 1 else "build/web").resolve()
    if not build.is_dir():
        raise SystemExit(f"Error: no existe {build}. Ejecuta flutter build web primero.")

    required = ("index.html", "flutter_bootstrap.js", "main.dart.js", "manifest.json")
    for name in required:
        if not (build / name).is_file():
            raise SystemExit(f"Error: falta {name} en el build de Flutter.")

    canvaskit = build / "canvaskit"
    if not canvaskit.is_dir() or not any(canvaskit.rglob("*.wasm")):
        raise SystemExit(
            "Error: falta CanvasKit local (canvaskit/*.wasm). "
            "No se puede garantizar carga offline."
        )

    bootstrap = (build / "flutter_bootstrap.js").read_text(encoding="utf-8")
    if "canvasKitBaseUrl" not in bootstrap or "canvaskit/" not in bootstrap:
        raise SystemExit("Error: el bootstrap no fuerza CanvasKit local.")

    html = (build / "index.html").read_text(encoding="utf-8")
    if "puzzle-sw.js" not in html:
        raise SystemExit("Error: index.html no registra puzzle-sw.js.")
    if "$FLUTTER_BASE_HREF" in html:
        raise SystemExit("Error: Flutter no sustituyo $FLUTTER_BASE_HREF.")

    files = sorted(
        file.relative_to(build).as_posix()
        for file in build.rglob("*")
        if file.is_file()
        and file.name not in {SW_NAME, "flutter_service_worker.js"}
        and not file.name.endswith((".map", ".js.map"))
    )

    # Una huella de todos los archivos hace que cada release genere una cache nueva.
    h = hashlib.sha256()
    for rel in files:
        h.update(rel.encode("utf-8"))
        h.update(b"\0")
        with (build / rel).open("rb") as stream:
            for chunk in iter(lambda: stream.read(128 * 1024), b""):
                h.update(chunk)
        h.update(b"\0")
    version = h.hexdigest()[:16]
    file_list = ["."] + files

    js = f"""/* Generado por tool/build_pwa.py; no editar en build/web manualmente. */
const CACHE_NAME = {json.dumps(PREFIX + version)};
const CACHE_PREFIX = {json.dumps(PREFIX)};
const ROOT = new URL('./', self.location.href);
const RESOURCES = {json.dumps(file_list, ensure_ascii=False, separators=(',', ':'))};

self.addEventListener('install', event => {{
  event.waitUntil((async () => {{
    const cache = await caches.open(CACHE_NAME);
    const concurrency = 6;
    let next = 0;
    async function fetchNext() {{
      while (next < RESOURCES.length) {{
        const item = RESOURCES[next++];
        const url = new URL(item, ROOT).href;
        const response = await fetch(url, {{cache: 'reload'}});
        if (!response.ok) throw new Error('No se pudo precargar ' + url + ': ' + response.status);
        await cache.put(url, response);
      }}
    }}
    await Promise.all(Array.from({{length: concurrency}}, fetchNext));
    await self.skipWaiting();
  }})());
}});

self.addEventListener('activate', event => {{
  event.waitUntil((async () => {{
    const keys = await caches.keys();
    await Promise.all(keys
      .filter(key => key.startsWith(CACHE_PREFIX) && key !== CACHE_NAME)
      .map(key => caches.delete(key)));
    await self.clients.claim();
  }})());
}});

self.addEventListener('fetch', event => {{
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  if (url.origin !== ROOT.origin || !url.pathname.startsWith(ROOT.pathname)) return;
  event.respondWith((async () => {{
    const cache = await caches.open(CACHE_NAME);
    const cached = await cache.match(request, {{ignoreSearch: true}});
    if (cached) return cached;
    if (request.mode === 'navigate') {{
      const shell = await cache.match(new URL('index.html', ROOT).href);
      if (shell) return shell;
    }}
    return fetch(request);
  }})());
}});
"""
    (build / SW_NAME).write_text(js, encoding="utf-8")
    print(f"PWA offline: {len(file_list)} recursos, version={version}")
    print(f"Service worker generado: {build / SW_NAME}")


if __name__ == "__main__":
    main()
