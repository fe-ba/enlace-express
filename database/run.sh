#!/usr/bin/env bash
# Ejecuta un script suelto de database/ sin reinstalar (pruebas, consultas, informes).
# Uso:  database/run.sh <propietario|system|svc_gerencia|svc_centro|svc_mesa|svc_mensajero|svc_cliente> <ruta relativa a database/> [parametros del script (&1, &2...)]
# Ejemplo: database/run.sh propietario tests/prueba_vistas.sql
# Las cuentas svc_* se conectan como lo hara la aplicacion: con
# CURRENT_SCHEMA = BD_ENLACE_EXPRESS (decision 12.1).
# Las contrasenas salen de .env y viajan por la entrada estandar de sqlplus.
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ $# -lt 2 ]]; then
    echo "Uso: database/run.sh <propietario|system> <ruta relativa a database/>" >&2
    exit 2
fi
set -a
# shellcheck disable=SC1091
source "$RAIZ/.env"
set +a
case "$1" in
    propietario) usuario="BD_ENLACE_EXPRESS"; clave="$PROPIETARIO_PASSWORD" ;;
    system)      usuario="SYSTEM";            clave="$ORACLE_PASSWORD" ;;
    svc_gerencia|svc_centro|svc_mesa|svc_mensajero|svc_cliente)
        usuario="$1"
        variable="${1^^}_PASSWORD"
        clave="${!variable}"
        esquema="BD_ENLACE_EXPRESS" ;;
    *) echo "Primer argumento invalido: $1 (use propietario, system o svc_*)" >&2; exit 2 ;;
esac
[[ -f "$RAIZ/database/$2" ]] || { echo "No existe database/$2" >&2; exit 2; }

{
    echo "WHENEVER SQLERROR EXIT FAILURE"
    echo "SET VERIFY OFF"
    echo "SET SERVEROUTPUT ON SIZE UNLIMITED"
    echo "CONNECT ${usuario}/\"${clave}\"@//localhost/FREEPDB1"
    echo "ALTER SESSION SET TIME_ZONE = 'America/Bogota';"
    if [[ -n "${esquema:-}" ]]; then
        echo "ALTER SESSION SET CURRENT_SCHEMA = ${esquema};"
    fi
    echo "DEFINE envios_dia = ${VOLUMEN_ENVIOS_DIA:-900}"
    echo "@/opt/enlace/database/$2 ${*:3}"
    echo "EXIT"
} | docker exec -i -e NLS_LANG=.AL32UTF8 -e TZ=America/Bogota enlace-oracle sqlplus -s /nolog
