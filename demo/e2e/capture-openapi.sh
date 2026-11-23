#!/usr/bin/env bash
# Guarda la documentacion OpenAPI de la aplicacion en marcha y una captura de Swagger UI en docs/evidence/:
#   docs/evidence/13_openapi.json    (GET /v3/api-docs, sin sesion)
#   docs/evidence/13_swagger_ui.png  (Chromium sin cabeza con Playwright en Docker)
# Requiere la aplicacion levantada (demo/start.sh).
# Uso:  demo/e2e/capture-openapi.sh
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
E2E="$RAIZ/demo/e2e"
SALIDA="$RAIZ/docs/evidence"
IMAGEN="mcr.microsoft.com/playwright:v1.49.1-noble"
URL_APP="${URL_APP:-http://localhost:8080/}"

if [[ "$(curl -s -o /dev/null -w '%{http_code}' "${URL_APP}api/salud" || true)" != "200" ]]; then
    echo "La aplicacion no responde en $URL_APP. Ejecute demo/start.sh primero." >&2
    exit 1
fi

curl -s "${URL_APP}v3/api-docs" | python3 -c "
import json, sys
json.dump(json.load(sys.stdin), sys.stdout, ensure_ascii=False, indent=2)
sys.stdout.write('\n')" > "$SALIDA/13_openapi.json"
echo "OpenAPI: $SALIDA/13_openapi.json"

docker run --rm --network host -u "$(id -u):$(id -g)" -e HOME=/tmp -e npm_config_cache=/tmp/npm -e URL_APP \
    -v "$E2E":/e2e -v "$SALIDA":/salida -w /e2e "$IMAGEN" \
    sh -c '[ -d node_modules ] || npm ci --no-audit --no-fund >/dev/null; node openapi.mjs'
