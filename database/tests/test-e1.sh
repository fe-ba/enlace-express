#!/usr/bin/env bash
# Prueba de la extension E1: logica con el propietario (06_pruebas_e1.sql), registro
# desde la aplicacion con svc_cliente (06b a 06d) y permisos. Guarda la salida en
# docs/evidence/09_extension_e1.txt y termina con error si hay FALLA.
set -uo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EJECUTAR="$RAIZ/database/run.sh"
SALIDA="$RAIZ/docs/evidence/09_extension_e1.txt"
filtrar() { grep -E '^(---|OK|FALLA|E1 |SVC_|svc_cliente:)' || true; }

{
    echo "Pruebas de la extension E1 (usuarios de la aplicacion y codigos de activacion)"
    echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "Comando: database/tests/test-e1.sh"
    echo
    echo "=== Parte 1: logica (propietario, ROLLBACK al final) ==="
    "$EJECUTAR" propietario tests/06_pruebas_e1.sql 2>&1 | filtrar
    echo
    echo "=== Parte 2: la aplicacion (svc_cliente) ==="
    preparar="$("$EJECUTAR" propietario tests/06b_e1_preparar.sql 2>&1)"
    codigo="$(grep -o '^CODIGO|.*' <<< "$preparar" | cut -d'|' -f2)"
    if [[ -z "$codigo" ]]; then echo "FALLA no se pudo preparar la prueba: $preparar"; else
        echo "(el administrador genero un codigo para el mensajero de prueba 9301)"
        "$EJECUTAR" svc_cliente tests/06c_e1_aplicacion.sql "$codigo" 2>&1 | filtrar
    fi
    "$EJECUTAR" propietario tests/06d_e1_limpiar.sql > /dev/null 2>&1
    echo
    echo "=== Parte 3: las demas cuentas de servicio no tienen acceso a E1 ==="
    for cuenta in svc_gerencia svc_centro svc_mesa svc_mensajero; do
        "$EJECUTAR" "$cuenta" tests/06e_e1_otras_cuentas.sql 2>&1 | filtrar
    done
} > "$SALIDA"

cat "$SALIDA"
total_ok="$(grep -c '^OK' "$SALIDA" || true)"
total_falla="$(grep -c '^FALLA' "$SALIDA" || true)"
echo
echo "Total E1: $total_ok OK, $total_falla FALLA" | tee -a "$SALIDA"
[[ "$total_falla" -eq 0 && "$total_ok" -gt 0 ]]
