#!/usr/bin/env bash
# Instala el esquema en un Oracle desechable (gvenzl/oracle-free:23-slim) y exige que todas las cifras del
# documento den OK (VERIFICACION_ESTRICTA=1). No usa .env ni secretos: las contrasenas se generan al azar
# en cada corrida y el contenedor se elimina al terminar. Lo usa la CI (.github/workflows/ci.yml) y ci/local.sh.
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGEN="gvenzl/oracle-free:23-slim"
NOMBRE="enlace-ci-cifras-$$"

clave() { printf 'Ee%s7' "$(openssl rand -hex 10)"; }
export ORACLE_PASSWORD PROPIETARIO_PASSWORD SVC_GERENCIA_PASSWORD SVC_CENTRO_PASSWORD \
       SVC_MESA_PASSWORD SVC_MENSAJERO_PASSWORD SVC_CLIENTE_PASSWORD
ORACLE_PASSWORD="$(clave)"
PROPIETARIO_PASSWORD="$(clave)"
SVC_GERENCIA_PASSWORD="$(clave)"
SVC_CENTRO_PASSWORD="$(clave)"
SVC_MESA_PASSWORD="$(clave)"
SVC_MENSAJERO_PASSWORD="$(clave)"
SVC_CLIENTE_PASSWORD="$(clave)"

docker run -d --name "$NOMBRE" -e ORACLE_PASSWORD -e TZ=America/Bogota \
    -v "$RAIZ/database:/opt/enlace/database:ro" "$IMAGEN" > /dev/null
EVIDENCIA="$(mktemp)"
trap 'docker rm -f "$NOMBRE" > /dev/null 2>&1 || true; rm -f "$EVIDENCIA"' EXIT

echo "Esperando a que Oracle este listo..."
listo=0
for _ in $(seq 1 120); do
    if docker logs "$NOMBRE" 2>&1 | grep -q 'DATABASE IS READY TO USE!'; then
        listo=1
        break
    fi
    sleep 5
done
if [[ "$listo" != 1 ]]; then
    echo "Oracle no quedo listo en 10 minutos." >&2
    docker logs "$NOMBRE" 2>&1 | tail -20 >&2
    exit 1
fi

ENLACE_CONTENEDOR="$NOMBRE" ENLACE_EVIDENCIA="$EVIDENCIA" VERIFICACION_ESTRICTA=1 "$RAIZ/database/install.sh"
echo
echo "Cifras del documento verificadas: todas OK."
