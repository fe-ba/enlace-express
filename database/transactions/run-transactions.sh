#!/usr/bin/env bash
# Reinstala la base (database/install.sh), ejecuta T01 a T12 en cadena con la cuenta
# de servicio de cada usuario y guarda docs/evidence/06_transacciones/Txx.txt
# y resumen.txt. Termina con error si algun caso da FALLA.
set -uo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DESTINO="$RAIZ/docs/evidence/06_transacciones"
EJECUTAR="$RAIZ/database/run.sh"
mkdir -p "$DESTINO"

echo "Reinstalando la base desde cero..."
if ! "$RAIZ/database/install.sh" > "$DESTINO/instalacion.log" 2>&1; then
    echo "La instalacion fallo (ver $DESTINO/instalacion.log)" >&2
    exit 1
fi

# id:archivo:cuenta:usuario:reglas
TRANSACCIONES=(
    "T01:T01_registrar_solicitud:svc_mesa:U3:RN15"
    "T02:T02_registrar_envio:svc_mesa:U3:RN01 a RN04, RN12"
    "T03:T03_recolectar:svc_mensajero:U4:RN12"
    "T04:T04_recibir_clasificar:svc_centro:U2:RN03, RN12"
    "T05:T05_armar_despacho:svc_centro:U2:RN07, RN09 a RN12"
    "T06:T06_registrar_entrega:svc_mensajero:U4:RN05, RN06, RN08, RN12"
    "T07:T07_registrar_novedad:svc_mensajero:U4:RN07, RN08, RN12"
    "T08:T08_registrar_devolucion:svc_mensajero:U4:RN05, RN07, RN12"
    "T09:T09_cerrar_despacho:svc_centro:U2:--"
    "T10:T10_gestionar_novedad:svc_mesa:U3:--"
    "T11:T11_reclamacion:svc_mesa:U3:RN14"
    "T12:T12_anular_envio:svc_mesa:U3:RN12, RN16"
)

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
errores=0
for item in "${TRANSACCIONES[@]}"; do
    IFS=: read -r id archivo cuenta usuario reglas <<< "$item"
    if [[ "$id" == "T08" ]]; then
        "$EJECUTAR" propietario transactions/T08_preparacion.sql > "$DESTINO/T08_preparacion.txt" 2>&1 \
            || { echo "T08_preparacion fallo (ver T08_preparacion.txt)" >&2; errores=$((errores + 1)); }
    fi
    fecha="$(date '+%Y-%m-%d %H:%M:%S %Z')"
    {
        echo "Transaccion: $id ($archivo.sql)"
        echo "Cuenta:      $cuenta (CURRENT_SCHEMA = BD_ENLACE_EXPRESS)"
        echo "Usuario:     $usuario"
        echo "Reglas:      $reglas"
        echo "Fecha:       $fecha"
        echo
        "$EJECUTAR" "$cuenta" "transactions/$archivo.sql" 2>&1 | grep -v '^Session altered\.$' | grep -v '^PL/SQL procedure successfully completed\.$' | grep -v '^$'
    } > "$DESTINO/$id.txt"
    grep '^RESULTADO|' "$DESTINO/$id.txt" >> "$TMP"
    # un error fuera de los casos (compilacion, permisos) aborta el script de la transaccion
    if grep -q '^ERROR at line' "$DESTINO/$id.txt" || grep -qv -e '|OK$' -e '|FALLA$' <(grep '^RESULTADO|' "$DESTINO/$id.txt"); then
        echo "$id: el script termino con error (ver $DESTINO/$id.txt)" >&2
        errores=$((errores + 1))
    fi
    printf '%s: %s casos\n' "$id" "$(grep -c '^RESULTADO|' "$DESTINO/$id.txt")"
done

# la secuencia de guias avanza con los rechazos y las pruebas: se deja tras la ultima guia
"$EJECUTAR" propietario tests/restaurar_secuencia_guias.sql > /dev/null

{
    printf '%-4s | %-9s | %-95s | %-75s | %-50s | %s\n' "Tx" "Caso" "Descripcion" "Esperado" "Obtenido" "Resultado"
    awk -F'|' '{ printf "%-4s | %-9s | %-95s | %-75s | %-50s | %s\n", $2, $3, $4, $5, $6, $7 }' "$TMP"
    echo
    ok="$(grep -c '|OK$' "$TMP" || true)"
    falla="$(grep -c '|FALLA$' "$TMP" || true)"
    validos="$(grep -c '^RESULTADO|T[0-9]*|valido|' "$TMP" || true)"
    rechazados="$(grep -c '^RESULTADO|T[0-9]*|rechazado|' "$TMP" || true)"
    echo "Total: $((ok + falla)) casos ($validos validos, $rechazados rechazados): $ok OK, $falla FALLA"
} > "$DESTINO/resumen.txt"
cat "$DESTINO/resumen.txt"
[[ "$errores" -eq 0 ]] && ! grep -q '|FALLA$' "$TMP"
