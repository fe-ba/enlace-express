#!/usr/bin/env bash
# Ejecuta los informes I01 a I07 con la cuenta de servicio del primer usuario
# de cada uno (tabla de informes del capitulo 6) y guarda la salida en
# docs/evidence/07_informes/<modo>/Ixx.txt y resumen.txt.
# Uso: database/reports/run-reports.sh [fijos|volumen]
#   fijos   (por defecto) base con los datos fijos: despacho 15, guia EE0000000000003, centro 1.
#   volumen base cargada con database/install.sh --volumen: parametros tomados de los datos y
#           listados largos recortados a las primeras 20 filas mas el total.
set -uo pipefail

MODO="${1:-fijos}"
[[ "$MODO" == "fijos" || "$MODO" == "volumen" ]] || { echo "Modo invalido: $MODO" >&2; exit 2; }
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EJECUTAR="$RAIZ/database/run.sh"
DESTINO="$RAIZ/docs/evidence/07_informes/$MODO"
mkdir -p "$DESTINO"

if [[ "$MODO" == "volumen" ]]; then
    IFS='|' read -r DESPACHO GUIA CLIENTE < <("$EJECUTAR" propietario reports/parametros_volumen.sql 2>&1 | grep '|' | head -1 | tr -d ' ')
else
    DESPACHO=15; GUIA=EE0000000000003; CLIENTE=1
fi
OTRO_CLIENTE=$((CLIENTE + 1))
CENTRO=1

# recorta un listado largo a las primeras 20 filas de datos y la linea final de total
recortar() {
    if [[ "$MODO" != "volumen" ]]; then cat; return; fi
    awk '
        { lineas[NR] = $0 }
        END {
            inicio = 0
            for (i = 1; i <= NR; i++) if (lineas[i] ~ /^-+( +-+)*$/) { inicio = i; break }
            if (inicio == 0 || NR - inicio < 30) { for (i = 1; i <= NR; i++) print lineas[i]; exit }
            for (i = 1; i <= inicio + 20; i++) print lineas[i]
            print "... (se muestran las primeras 20 filas; total en la ultima linea)"
            for (i = NR; i >= 1; i--) if (lineas[i] ~ /selected/) { print ""; print lineas[i]; break }
        }'
}
limpiar() { grep -v '^Session altered\.$' | sed '/./,$!d'; }

# id:archivo:cuenta:parametros
INFORMES=(
    "I01:I01_planilla_ruta:svc_mensajero:$DESPACHO"
    "I02:I02_seguimiento_envio:svc_cliente:$GUIA $CLIENTE"
    "I03:I03_envios_por_estado:svc_gerencia:$CENTRO 0"
    "I04:I04_cumplimiento_entregas:svc_gerencia:$CENTRO"
    "I05:I05_envios_por_despachar:svc_centro:$CENTRO"
    "I06:I06_novedades_abiertas:svc_mesa:"
    "I07:I07_reclamaciones_pendientes:svc_gerencia:"
)

fallas=0
printf '%-5s %-14s %-28s %s\n' "Id" "Cuenta" "Parametros" "Filas" > "$DESTINO/resumen.txt"
contar() {
    if grep -q 'no rows selected' <<< "$1"; then echo 0
    else grep -Eo '^ *[0-9]+ rows? selected' <<< "$1" | grep -Eo '[0-9]+' | tail -1; fi
}
for item in "${INFORMES[@]}"; do
    IFS=: read -r id archivo cuenta params <<< "$item"
    fecha="$(date '+%Y-%m-%d %H:%M:%S %Z')"
    # shellcheck disable=SC2086
    salida="$("$EJECUTAR" "$cuenta" "reports/$archivo.sql" $params 2>&1)"; codigo=$?
    cuerpo="$(printf '%s\n' "$salida" | limpiar)"
    filas="ERROR"
    [[ $codigo -eq 0 ]] && filas="$(contar "$cuerpo")" || fallas=$((fallas + 1))
    {
        echo "Informe: $id ($archivo.sql)  Modo: $MODO"
        echo "Cuenta:  $cuenta (CURRENT_SCHEMA = BD_ENLACE_EXPRESS)"
        echo "Parametros: ${params:-ninguno}"
        echo "Fecha:   $fecha"
        echo "Filas:   $filas"
        echo
        printf '%s\n' "$cuerpo" | recortar
    } > "$DESTINO/$id.txt"
    printf '%-5s %-14s %-28s %s\n' "$id" "$cuenta" "${params:-ninguno}" "$filas" | tee -a "$DESTINO/resumen.txt"

    if [[ "$id" == "I02" ]]; then
        # el portal filtra por cliente: con otro id_cliente la misma guia no devuelve filas
        salida2="$("$EJECUTAR" svc_cliente reports/I02_seguimiento_envio.sql "$GUIA" "$OTRO_CLIENTE" 2>&1)"; codigo2=$?
        cuerpo2="$(printf '%s\n' "$salida2" | limpiar)"
        filas2="ERROR"
        [[ $codigo2 -eq 0 ]] && filas2="$(contar "$cuerpo2")" || fallas=$((fallas + 1))
        {
            echo
            echo "---- Misma guia con otro id_cliente ($OTRO_CLIENTE): el portal no debe ver el envio ----"
            echo "Filas:   $filas2"
            echo
            printf '%s\n' "$cuerpo2"
        } >> "$DESTINO/I02.txt"
        printf '%-5s %-14s %-28s %s\n' "I02b" "svc_cliente" "$GUIA $OTRO_CLIENTE" "$filas2" | tee -a "$DESTINO/resumen.txt"
        [[ "$filas2" == "0" ]] || fallas=$((fallas + 1))
    fi
done
[[ "$fallas" -eq 0 ]] && echo "Informes ($MODO): sin errores" || { echo "Informes ($MODO): $fallas con error" >&2; exit 1; }
