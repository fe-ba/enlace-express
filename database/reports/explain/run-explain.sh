#!/usr/bin/env bash
# EXPLAIN PLAN de siete consultas que deben usar los indices del capitulo 5.
# Requiere la base cargada con volumen y estadisticas (database/install.sh --volumen).
# Guarda docs/evidence/08_explain/E1.txt ... E7.txt y resumen.txt. No usa hints:
# si el optimizador no elige el indice, el plan real queda como evidencia.
set -uo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
EJECUTAR="$RAIZ/database/run.sh"
DESTINO="$RAIZ/docs/evidence/08_explain"
mkdir -p "$DESTINO"

# id:archivo:indice esperado
PLANES=(
    "E1:E1_recorrido_guia:EVENTO_GUIA_FECHA_UX"
    "E2:E2_estado_actual_guia:EVENTO_GUIA_FECHA_UX"
    "E3:E3_envios_periodo:ENVIO_FECHA_REGISTRO_IX"
    "E4:E4_despachos_del_dia:DESPACHO_FECHA_IX"
    "E5:E5_novedades_abiertas:NOVEDAD_ESTADO_IX"
    "E6:E6_reclamaciones_pendientes:RECLAMACION_ESTADO_IX"
    "E7:E7_planilla_despacho:ASIGNACION_DESPACHO_FK_IX"
)
errores=0
printf '%-4s %-26s %-28s %s\n' "Id" "Archivo" "Indice esperado" "Aparece" > "$DESTINO/resumen.txt"
for item in "${PLANES[@]}"; do
    IFS=: read -r id archivo indice <<< "$item"
    ruta="$RAIZ/database/reports/explain/$archivo.sql"
    consulta="$(grep -m1 '^-- Consulta:' "$ruta" | sed 's/^-- Consulta: //')"
    salida="$("$EJECUTAR" propietario "reports/explain/$archivo.sql" 2>&1)"; codigo=$?
    cuerpo="$(printf '%s\n' "$salida" | grep -v '^Session altered\.$' | sed '/./,$!d')"
    if [[ $codigo -ne 0 ]]; then errores=$((errores + 1)); aparece="ERROR"
    else
        # solo se cuenta el primer plan del archivo (el de E3M es el del mes)
        primero="$(printf '%s\n' "$cuerpo" | awk '/^El mismo informe/ { exit } { print }')"
        if grep -q "$indice" <<< "$primero"; then aparece="SÍ"; else aparece="NO"; fi
    fi
    {
        echo "Consulta: $consulta"
        echo "Indice esperado: $indice. Aparece en el plan: $aparece"
        echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        echo
        grep '^-- ' "$ruta" | grep -v '^-- Consulta:' | grep -v '^-- Indice esperado:' | sed 's/^-- /Nota: /'
        echo
        printf '%s\n' "$cuerpo"
    } > "$DESTINO/$id.txt"
    printf '%-4s %-26s %-28s %s\n' "$id" "$archivo" "$indice" "$aparece" | tee -a "$DESTINO/resumen.txt"
done
[[ "$errores" -eq 0 ]]
