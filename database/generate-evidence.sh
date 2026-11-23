#!/usr/bin/env bash
# Regenera todas las evidencias del nivel 1, en orden y desde cero:
#  1. instalacion normal y verificacion de cifras
#  2. pruebas de reglas, de permisos y de la extension E1
#  3. conteo de datos fijos, consultas C1 a C10 e informes con datos fijos
#  4. transacciones T01 a T12 (reinstalan) y concurrencia
#  5. instalacion con volumen, conteo, informes con volumen y EXPLAIN PLAN
#  6. reinstalacion normal: la base queda con los datos fijos, lista para la aplicacion
# Imprime un resumen OK/FALLA de cada paso y termina con error si alguno falla.
set -uo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EV="$RAIZ/docs/evidence"
EJECUTAR="$RAIZ/database/run.sh"
export VERIFICACION_ESTRICTA=1
INICIO_TOTAL=$SECONDS
RESUMEN=()
FALLAS=0
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

# paso "nombre" funcion: ejecuta la funcion, mide el tiempo y anota OK/FALLA
paso() {
    local nombre="$1"; shift
    local t0=$SECONDS
    echo ">>> $nombre"
    if "$@" > "$LOG" 2>&1; then estado="OK"; else estado="FALLA"; FALLAS=$((FALLAS + 1)); tail -15 "$LOG"; fi
    local t=$((SECONDS - t0))
    RESUMEN+=("$(printf '%-6s %-62s %4d s' "$estado" "$nombre" "$t")")
    echo "    $estado (${t} s)"
}

cifras_sin_falla() { ! grep -q 'FALLA' "$EV/01_verificacion_cifras.txt"; }

pruebas_reglas() {
    local salida
    salida="$("$EJECUTAR" propietario tests/02_pruebas_reglas.sql 2>&1)" || { echo "$salida"; return 1; }
    {
        echo "Pruebas de reglas de negocio (RN02, RN04 a RN08, RN10 a RN12, RN15), con los datos de seed cargados"
        echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        echo "Comando: database/run.sh propietario tests/02_pruebas_reglas.sql"
        echo
        printf '%s\n' "$salida" | sed -n '/^--- Datos base/,$p' | grep -v '^$'
    } > "$EV/02_pruebas_reglas.txt"
    grep -q ' 0 FALLA' "$EV/02_pruebas_reglas.txt" && ! grep -q '^FALLA' "$EV/02_pruebas_reglas.txt"
}

conteo_fijos() {
    {
        echo "Conteo de datos cargados (database/seed)"
        echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        echo
        "$EJECUTAR" propietario tests/04_conteo_datos.sql 2>&1 | grep -v '^$' | grep -v 'Session altered'
    } > "$EV/04_datos_conteo.txt"
}

conteo_volumen() {
    mkdir -p "$EV/07_volumen"
    {
        echo "Datos de volumen (database/seed/volume/generar_volumen.sql): conteo y tamano"
        echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        echo
        echo "Carga (salida del generador)"
        sed 's/^VOLUMEN|//; s/|/: /' "$EV/07_volumen/carga.txt"
        echo
        "$EJECUTAR" propietario tests/05_conteo_volumen.sql 2>&1 | grep -v '^$' | grep -v 'Session altered'
    } > "$EV/07_volumen/conteo.txt"
}

paso "1. Instalacion normal (con verificacion estricta de cifras)" "$RAIZ/database/install.sh"
paso "2. Cifras del documento: 0 FALLA" cifras_sin_falla
paso "3. Pruebas de reglas de negocio (65 casos)" pruebas_reglas
paso "4. Pruebas de permisos de las 5 cuentas" "$RAIZ/database/tests/test-grants.sh"
paso "5. Extension E1: codigos de activacion y usuarios (74 casos)" "$RAIZ/database/tests/test-e1.sh"
paso "5b. Conteo de los datos fijos" conteo_fijos
paso "6. Consultas C1 a C10 con la cuenta de cada usuario" "$RAIZ/database/queries/run-queries.sh"
paso "7. Consultas iguales al documento (10 IGUAL)" "$RAIZ/database/tests/compare-queries.sh"
paso "8. Informes I01 a I07 con datos fijos" "$RAIZ/database/reports/run-reports.sh" fijos
paso "9. Transacciones T01 a T12 (reinstala y ejecuta)" "$RAIZ/database/transactions/run-transactions.sh"
paso "10. Concurrencia (SELECT FOR UPDATE NOWAIT)" "$RAIZ/database/transactions/concurrency.sh"
paso "11. Instalacion con volumen (900 envios por dia habil)" "$RAIZ/database/install.sh" --volumen
paso "12. Conteo y tamano de los datos de volumen" conteo_volumen
paso "13. Informes I01 a I07 con volumen" "$RAIZ/database/reports/run-reports.sh" volumen
paso "14. EXPLAIN PLAN E1 a E7" "$RAIZ/database/reports/explain/run-explain.sh"
paso "15. Reinstalacion normal (datos fijos) para la aplicacion" "$RAIZ/database/install.sh"
paso "16. Cifras finales: 0 FALLA" cifras_sin_falla

echo
echo "================ Resumen ================"
printf '%s\n' "${RESUMEN[@]}"
echo "Tiempo total: $((SECONDS - INICIO_TOTAL)) s"
if [[ "$FALLAS" -gt 0 ]]; then echo "Pasos con FALLA: $FALLAS"; exit 1; fi
echo "Todos los pasos OK"
