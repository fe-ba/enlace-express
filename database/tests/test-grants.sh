#!/usr/bin/env bash
# Corre la prueba de permisos con las 5 cuentas de servicio y guarda la salida
# en docs/evidence/03_prueba_permisos.txt. Termina con error si hay FALLA.
# Requiere la base instalada con datos (database/install.sh).
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SALIDA="$RAIZ/docs/evidence/03_prueba_permisos.txt"
EJECUTAR="$RAIZ/database/run.sh"

{
    echo "Prueba de permisos de las cuentas de servicio (RN16 y tabla de roles)"
    echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "Comando: database/tests/test-grants.sh"
    echo
    for cuenta in svc_gerencia svc_centro svc_mesa svc_mensajero svc_cliente; do
        "$EJECUTAR" "$cuenta" tests/03_prueba_permisos.sql 2>&1 \
            | grep -E '^(---|OK|FALLA|SVC_)' || true
    done
} > "$SALIDA"

# pr_registrar_envio consume la secuencia de guias aunque se haga ROLLBACK
"$EJECUTAR" propietario tests/restaurar_secuencia_guias.sql > /dev/null

cat "$SALIDA"
echo
total_ok="$(grep -c '^OK' "$SALIDA" || true)"
total_falla="$(grep -c '^FALLA' "$SALIDA" || true)"
echo "Total: $total_ok OK, $total_falla FALLA" | tee -a "$SALIDA"
[[ "$total_falla" -eq 0 ]]
