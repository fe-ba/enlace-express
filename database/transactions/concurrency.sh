#!/usr/bin/env bash
# Prueba de concurrencia del bloqueo pesimista (decision C4). La sesion A
# (svc_centro) bloquea una fila de ENVIO con SELECT ... FOR UPDATE sin confirmar;
# la sesion B (svc_mesa) intenta lo mismo con NOWAIT y recibe ORA-00054; cuando A
# hace ROLLBACK, B lo reintenta y lo consigue. Guarda la salida en
# docs/evidence/06_transacciones/concurrencia.txt. Requiere la base con datos.
set -uo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EJECUTAR="$RAIZ/database/run.sh"
SALIDA="$RAIZ/docs/evidence/06_transacciones/concurrencia.txt"
mkdir -p "$(dirname "$SALIDA")"
A="$(mktemp)"; B="$(mktemp)"
trap 'rm -f "$A" "$B"' EXIT

"$EJECUTAR" svc_centro transactions/concurrencia_A.sql > "$A" 2>&1 &
pid_a=$!

# espera a que A tenga el bloqueo (maximo 30 s)
for _ in $(seq 1 60); do
    grep -q 'A: bloqueo obtenido' "$A" && break
    sleep 0.5
done
if ! grep -q 'A: bloqueo obtenido' "$A"; then
    echo "A no obtuvo el bloqueo" >&2; cat "$A" >&2; exit 1
fi

"$EJECUTAR" svc_mesa transactions/concurrencia_B.sql > "$B" 2>&1
wait "$pid_a"

{
    echo "Prueba de concurrencia: SELECT ... FOR UPDATE (decision C4)"
    echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "Fila: envio EE0000000000028. Sesion A: svc_centro; sesion B: svc_mesa (FOR UPDATE NOWAIT)."
    echo
    { grep -h '^[0-9][0-9]:[0-9][0-9]:' "$A" "$B"; } | sort
} > "$SALIDA"
cat "$SALIDA"

echo
grep -q 'B: intento 1 rechazado: ORA-00054' "$SALIDA" \
    && grep -q 'B: intento [0-9]* consigue el bloqueo' "$SALIDA" \
    && echo "CONCURRENCIA OK: B recibio ORA-00054 mientras A tenia la fila y la consiguio despues" \
    || { echo "CONCURRENCIA FALLA"; exit 1; }
