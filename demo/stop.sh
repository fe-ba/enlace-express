#!/usr/bin/env bash
# Detiene la aplicacion de la demostracion usando el PID guardado por start.sh.
set -euo pipefail

DEMO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCHIVO="$DEMO/.app.pid"

if [[ ! -f "$ARCHIVO" ]]; then
    echo "No hay aplicacion de la demostracion registrada."
    exit 0
fi
PID="$(cat "$ARCHIVO")"
# solo se mata el proceso si todavia es un java del jar de Enlace Express
if [[ -n "$PID" ]] && [[ "$(tr '\0' ' ' < "/proc/$PID/cmdline" 2>/dev/null || true)" == *enlace-express* ]]; then
    kill "$PID"
    for _ in $(seq 1 30); do
        kill -0 "$PID" 2>/dev/null || break
        sleep 1
    done
    kill -0 "$PID" 2>/dev/null && kill -9 "$PID"
    echo "Aplicacion detenida (PID $PID)."
else
    echo "El PID $PID ya no corresponde a la aplicacion."
fi
rm -f "$ARCHIVO"
