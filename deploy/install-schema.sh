#!/usr/bin/env bash
# Instala el esquema de Enlace Express UNA SOLA VEZ en el Oracle del compose de produccion (decision G2): el
# despliegue continuo actualiza solo la aplicacion; un cambio de esquema se hace reinstalando con este script.
# Reutiliza database/install.sh con ENLACE_CONTENEDOR, verifica las cifras del documento en modo estricto y carga
# los datos fijos de demostracion.
#
# Uso:  deploy/install-schema.sh [--reinstalar]
# Requiere el .env de la raiz del repositorio (mismas contrasenas que usa el compose) y el contenedor
# enlace-prod-oracle arriba. Si el esquema ya existe, no hace nada: con --reinstalar BORRA todo y lo vuelve a crear.
# Variable opcional: ENLACE_CONTENEDOR (por defecto enlace-prod-oracle).
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTENEDOR="${ENLACE_CONTENEDOR:-enlace-prod-oracle}"
REINSTALAR=0
for argumento in "$@"; do
    case "$argumento" in
        --reinstalar) REINSTALAR=1 ;;
        *) echo "Opcion desconocida: $argumento (use --reinstalar)" >&2; exit 2 ;;
    esac
done

if [[ ! -f "$RAIZ/.env" ]]; then
    echo "Falta $RAIZ/.env (copie .env.example y complete las contrasenas)." >&2
    exit 1
fi
set -a
# shellcheck disable=SC1091
source "$RAIZ/.env"
set +a

estado="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}sin_salud{{end}}' "$CONTENEDOR" 2>/dev/null || echo inexistente)"
if [[ "$estado" != "healthy" ]]; then
    echo "El contenedor $CONTENEDOR no esta healthy (estado: $estado)." >&2
    echo "Levante el compose: docker compose --env-file .env -f deploy/docker-compose.yml up -d" >&2
    exit 1
fi

existe="$(docker exec -i "$CONTENEDOR" sqlplus -s /nolog <<SQL | grep -Eo '[0-9]+' | head -1
CONNECT SYSTEM/"$ORACLE_PASSWORD"@//localhost/FREEPDB1
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT COUNT(*) FROM dba_users WHERE username = 'BD_ENLACE_EXPRESS';
EXIT
SQL
)"
if [[ "${existe:-0}" != "0" && "$REINSTALAR" != "1" ]]; then
    echo "El esquema BD_ENLACE_EXPRESS ya esta instalado en $CONTENEDOR: no se toca." >&2
    echo "Para borrarlo y reinstalarlo: deploy/install-schema.sh --reinstalar" >&2
    exit 0
fi

EVIDENCIA="$(mktemp)"
trap 'rm -f "$EVIDENCIA"' EXIT
ENLACE_CONTENEDOR="$CONTENEDOR" ENLACE_EVIDENCIA="$EVIDENCIA" VERIFICACION_ESTRICTA=1 "$RAIZ/database/install.sh"
echo
echo "Esquema instalado y cifras del documento verificadas en $CONTENEDOR."
