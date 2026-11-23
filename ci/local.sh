#!/usr/bin/env bash
# Ejecuta en el equipo los mismos pasos de la CI (.github/workflows/ci.yml), de principio a fin:
#   1. compila el frontend (aqui con Docker, porque el Node del sistema esta danado; la CI usa setup-node)
#   2. compila el backend y corre las pruebas unitarias y de integracion con Oracle en Testcontainers
#   3. instala el esquema en un Oracle desechable y verifica las cifras del documento en modo estricto
# Requiere Docker y Java 21 con Maven. No usa el Oracle del compose ni el .env.
# Uso:  ci/local.sh
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INICIO=$SECONDS
RESUMEN=()

paso() {
    local nombre="$1"; shift
    local t0=$SECONDS
    echo
    echo ">>> $nombre"
    "$@"
    RESUMEN+=("$(printf 'OK  %-70s %4d s' "$nombre" "$((SECONDS - t0))")")
}

backend() {
    (cd "$RAIZ/backend" && ENLACE_TESTCONTAINERS=true mvn -B -q verify)
}

paso "1. Compilar el frontend" "$RAIZ/frontend/build.sh"
paso "2. Backend: verify con Oracle en Testcontainers" backend
paso "3. Cifras del documento en modo estricto" "$RAIZ/ci/verify-figures.sh"

echo
echo "================ Resumen de la CI local ================"
printf '%s\n' "${RESUMEN[@]}"
echo "Tiempo total: $((SECONDS - INICIO)) s"
