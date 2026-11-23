#!/usr/bin/env bash
# Reinstala la base de datos de Enlace Express desde cero.
#
# Uso:  database/install.sh
# Requiere: .env en la raiz, contenedor enlace-oracle en estado healthy
# (docker compose up -d). No usa sudo y no escribe contrasenas en los .sql:
# viajan por la entrada estandar de sqlplus como variables de sustitucion.
#
# Fases:
#   1. SYSTEM:      database/admin/*.sql (limpia, espacios de tablas, esquema,
#                   roles, cuentas de servicio)
#   2. Propietario: database/schema, plsql, grants, seed, extensions (*.sql en
#                   orden alfabetico; las carpetas vacias se omiten)
#   3. SYSTEM:      database/tests/verificar_cifras.sql, con la salida
#                   guardada en docs/evidence/01_verificacion_cifras.txt
#
# Opciones:
#   --volumen   ademas de los datos fijos carga el conjunto de volumen
#               (database/seed/volume/generar_volumen.sql: agosto a octubre de
#               2026, 900 envios por dia habil; VOLUMEN_ENVIOS_DIA lo cambia).
#               Tambien se activa con VOLUMEN=1. Sin la opcion la instalacion
#               queda solo con los datos fijos.
# Variable opcional: VERIFICACION_ESTRICTA=1 hace fallar el script si alguna
# cifra da FALLA. Sin .env, las contrasenas pueden venir del entorno; ENLACE_CONTENEDOR
# y ENLACE_EVIDENCIA permiten usar otro contenedor y otro archivo de evidencia (CI y
# pruebas con Testcontainers).
set -euo pipefail

VOLUMEN="${VOLUMEN:-0}"
for argumento in "$@"; do
    case "$argumento" in
        --volumen) VOLUMEN=1 ;;
        *) echo "Opcion desconocida: $argumento (use --volumen)" >&2; exit 2 ;;
    esac
done

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Variables opcionales (la CI y las pruebas con Testcontainers usan otro contenedor y no tienen .env):
#   ENLACE_CONTENEDOR  nombre o id del contenedor de Oracle (por defecto enlace-oracle)
#   ENLACE_EVIDENCIA   archivo donde se guarda la verificacion de cifras (por defecto, el de docs/evidence)
CONTENEDOR="${ENLACE_CONTENEDOR:-enlace-oracle}"
RUTA_DB="/opt/enlace/database"
SERVICIO="//localhost/FREEPDB1"
EVIDENCIA="${ENLACE_EVIDENCIA:-$RAIZ/docs/evidence/01_verificacion_cifras.txt}"

VARIABLES_CLAVES=(ORACLE_PASSWORD PROPIETARIO_PASSWORD SVC_GERENCIA_PASSWORD SVC_CENTRO_PASSWORD
                  SVC_MESA_PASSWORD SVC_MENSAJERO_PASSWORD SVC_CLIENTE_PASSWORD)
# Las contrasenas ya definidas en el entorno mandan sobre las del .env; el .env es opcional si estan todas.
previas=()
for v in "${VARIABLES_CLAVES[@]}"; do
    [[ -n "${!v:-}" ]] && previas+=("$v=${!v}")
done
if [[ -f "$RAIZ/.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source "$RAIZ/.env"
    set +a
    for par in "${previas[@]}"; do
        export "$par"
    done
fi
for v in "${VARIABLES_CLAVES[@]}"; do
    if [[ -z "${!v:-}" ]]; then
        echo "Falta la variable $v (defina el .env en $RAIZ o el entorno)." >&2
        exit 1
    fi
done

# El contenedor del compose define su propio healthcheck; uno creado sin healthcheck (CI, Testcontainers)
# se acepta si esta en ejecucion. Un contenedor que aun esta arrancando se espera hasta 3 minutos.
estado_contenedor() {
    docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else if .State.Running}}en_ejecucion{{else}}detenido{{end}}' \
        "$CONTENEDOR" 2>/dev/null || echo inexistente
}
estado="$(estado_contenedor)"
for _ in $(seq 1 36); do
    [[ "$estado" == "starting" ]] || break
    sleep 5
    estado="$(estado_contenedor)"
done
if [[ "$estado" != "healthy" && "$estado" != "en_ejecucion" ]]; then
    echo "El contenedor $CONTENEDOR no esta listo (estado: $estado)." >&2
    echo "Ejecute: docker compose up -d" >&2
    exit 1
fi

# sqlplus <usuario> <variable_con_contrasena> <script>...
# Los scripts son rutas dentro del contenedor.
ejecutar() {
    local usuario="$1" clave="${!2}"; shift 2
    {
        echo "WHENEVER SQLERROR EXIT FAILURE"
        echo "WHENEVER OSERROR EXIT FAILURE"
        echo "SET SERVEROUTPUT ON SIZE UNLIMITED"
        echo "SET VERIFY OFF"
        echo "CONNECT ${usuario}/\"${clave}\"@${SERVICIO}"
        echo "ALTER SESSION SET TIME_ZONE = 'America/Bogota';"
        echo "DEFINE pwd_sistema = \"${ORACLE_PASSWORD}\""
        echo "DEFINE pwd_propietario = \"${PROPIETARIO_PASSWORD}\""
        echo "DEFINE pwd_svc_gerencia = \"${SVC_GERENCIA_PASSWORD}\""
        echo "DEFINE pwd_svc_centro = \"${SVC_CENTRO_PASSWORD}\""
        echo "DEFINE pwd_svc_mesa = \"${SVC_MESA_PASSWORD}\""
        echo "DEFINE pwd_svc_mensajero = \"${SVC_MENSAJERO_PASSWORD}\""
        echo "DEFINE pwd_svc_cliente = \"${SVC_CLIENTE_PASSWORD}\""
        echo "DEFINE envios_dia = ${VOLUMEN_ENVIOS_DIA:-900}"
        local s
        for s in "$@"; do
            if [[ "$s" == "@fin_propietario" ]]; then
                cat <<'SQL'
DECLARE
    n NUMBER;
BEGIN
    -- los ALTER TABLE de seed invalidan sus dependientes; se recompilan antes de comprobar
    DBMS_UTILITY.COMPILE_SCHEMA(USER, FALSE);
    SELECT COUNT(*) INTO n FROM user_objects WHERE status = 'INVALID';
    IF n > 0 THEN
        RAISE_APPLICATION_ERROR(-20999, 'Hay ' || n || ' objetos invalidos tras la instalacion');
    END IF;
END;
/
SQL
            else
                echo "PROMPT >>> $s"
                echo "@$s"
            fi
        done
        echo "EXIT"
    } | docker exec -i -e NLS_LANG=.AL32UTF8 -e TZ=America/Bogota "$CONTENEDOR" sqlplus -s /nolog
}

# Lista los .sql de las carpetas dadas, en orden alfabetico, como rutas del contenedor.
scripts_de() {
    local dir f
    for dir in "$@"; do
        [[ -d "$RAIZ/database/$dir" ]] || continue
        for f in $(find "$RAIZ/database/$dir" -maxdepth 1 -name '*.sql' -type f | sort); do
            echo "$RUTA_DB/$dir/$(basename "$f")"
        done
    done
}

echo "=== Fase 1: administracion (SYSTEM) ==="
mapfile -t admin < <(scripts_de admin)
ejecutar SYSTEM ORACLE_PASSWORD "${admin[@]}"

echo "=== Fase 2: objetos del propietario (BD_ENLACE_EXPRESS) ==="
mapfile -t objetos < <(scripts_de schema plsql grants seed)
if [[ "$VOLUMEN" == "1" ]]; then
    echo "(con datos de volumen: ${VOLUMEN_ENVIOS_DIA:-900} envios por dia habil)"
    # el generador va despues de los datos fijos y las identidades se ajustan de nuevo
    objetos+=("$RUTA_DB/seed/volume/generar_volumen.sql" "$RUTA_DB/seed/99_ajustar_identidades.sql")
fi
# extensiones (E1, ...) despues de los datos fijos y de los de volumen
mapfile -t extensiones < <(scripts_de extensions)
objetos+=("${extensiones[@]}")
LOG_FASE2="$(mktemp)"
trap 'rm -f "$LOG_FASE2"' EXIT
ejecutar BD_ENLACE_EXPRESS PROPIETARIO_PASSWORD "${objetos[@]}" "@fin_propietario" | tee "$LOG_FASE2"
if [[ "$VOLUMEN" == "1" ]]; then
    mkdir -p "$RAIZ/docs/evidence/07_volumen"
    grep '^VOLUMEN|' "$LOG_FASE2" > "$RAIZ/docs/evidence/07_volumen/carga.txt" || true
fi

echo "=== Fase 3: verificacion de cifras ==="
mkdir -p "$(dirname "$EVIDENCIA")"
{
    echo "Verificacion de cifras contra el documento"
    echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "Base: FREEPDB1, esquema BD_ENLACE_EXPRESS"
    echo
    ejecutar SYSTEM ORACLE_PASSWORD "$RUTA_DB/tests/verificar_cifras.sql" \
        | sed -n '/^CIFRA/,$p'
} | tee "$EVIDENCIA"

fallas="$(grep -c ' FALLA$' "$EVIDENCIA" || true)"
echo
echo "Cifras con FALLA: $fallas"
if [[ "${VERIFICACION_ESTRICTA:-0}" == "1" && "$fallas" -gt 0 ]]; then
    exit 1
fi
