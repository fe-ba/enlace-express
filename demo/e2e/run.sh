#!/usr/bin/env bash
# Prueba de punta a punta en navegador sin cabeza (Playwright en Docker) contra la demostracion levantada
# por demo/start.sh, con los usuarios demo_*. Guarda las capturas y el resumen en
# docs/evidence/10_aplicacion/.
#
# Uso:  demo/e2e/run.sh
# Puede correrse varias veces seguidas sobre la misma demostracion: cada corrida crea sus propias solicitudes
# y envios (las capturas y el resumen se reemplazan). Para volver al estado inicial: demo/start.sh.
# Variable opcional: URL_APP (por defecto http://localhost:8080/).
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
E2E="$RAIZ/demo/e2e"
SALIDA="$RAIZ/docs/evidence/10_aplicacion"
IMAGEN="mcr.microsoft.com/playwright:v1.49.1-noble"
URL_APP="${URL_APP:-http://localhost:8080/}"

if [[ ! -f "$RAIZ/.env" ]]; then
    echo "Falta .env" >&2
    exit 1
fi
set -a
# shellcheck disable=SC1091
source "$RAIZ/.env"
set +a
: "${DEMO_PASSWORD:?Defina DEMO_PASSWORD en .env}"

if [[ "$(curl -s -o /dev/null -w '%{http_code}' "${URL_APP}api/salud" || true)" != "200" ]]; then
    echo "La aplicacion no responde en $URL_APP. Ejecute demo/start.sh primero." >&2
    exit 1
fi

mkdir -p "$SALIDA"
rm -f "$SALIDA"/*.png "$SALIDA"/resumen.txt

docker run --rm --network host -u "$(id -u):$(id -g)" \
    -e HOME=/tmp -e npm_config_cache=/tmp/npm \
    -e DEMO_PASSWORD -e URL_APP \
    -v "$E2E":/e2e -v "$SALIDA":/salida -w /e2e "$IMAGEN" \
    sh -c '[ -d node_modules ] || npm ci --no-audit --no-fund >/dev/null; node walkthrough.mjs'
