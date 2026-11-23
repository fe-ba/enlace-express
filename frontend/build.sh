#!/usr/bin/env bash
# Compila el frontend con la imagen oficial de Node (el Node del sistema no se usa) y deja los
# archivos planos en backend/src/main/resources/static/. Uso:
#   frontend/build.sh            instala dependencias si faltan y compila
#   frontend/build.sh --limpio   reinstala las dependencias (npm ci) antes de compilar
# El cache de npm y node_modules quedan dentro de frontend/ (ignorados por git) y a nombre de
# su usuario, no de root.
set -euo pipefail

FRONTEND="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAIZ="$(cd "$FRONTEND/.." && pwd)"
IMAGEN="node:22-alpine"

if [[ "${1:-}" == "--limpio" ]]; then
    rm -rf "$FRONTEND/node_modules"
fi
instalar="[ -d node_modules ] || npm ci"
if [[ ! -f "$FRONTEND/package-lock.json" ]]; then
    instalar="npm install"   # primera vez: genera package-lock.json (se versiona)
fi

docker run --rm -u "$(id -u):$(id -g)" \
    -e HOME=/tmp -e npm_config_cache=/repo/frontend/.npm -e npm_config_update_notifier=false \
    -v "$RAIZ":/repo -w /repo/frontend "$IMAGEN" \
    sh -c "$instalar && npm run build"
echo "Frontend compilado en backend/src/main/resources/static/"
