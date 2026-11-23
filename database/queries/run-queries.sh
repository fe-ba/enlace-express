#!/usr/bin/env bash
# Ejecuta las consultas C1 a C10 con la cuenta de servicio del usuario
# principal de cada una (tabla de consultas del capitulo 6) y guarda cada
# salida en docs/evidence/05_consultas/Cnn.txt, mas resumen.txt.
# Si una consulta falla (por ejemplo por permisos) el error queda en su
# archivo, se sigue con las demas y el script termina con codigo 1.
set -uo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DESTINO="$RAIZ/docs/evidence/05_consultas"
EJECUTAR="$RAIZ/database/run.sh"
mkdir -p "$DESTINO"

# id:archivo:cuenta
CONSULTAS=(
    "C01:C01_datos_envio:svc_mesa"
    "C02:C02_recorrido_envio:svc_mesa"
    "C03:C03_planilla_despacho:svc_centro"
    "C04:C04_clasificados_sin_asignar:svc_centro"
    "C05:C05_envios_zona_modalidad:svc_gerencia"
    "C06:C06_mensajeros_novedades:svc_gerencia"
    "C07:C07_envios_gestion:svc_mesa"
    "C08:C08_clientes_todas_modalidades:svc_gerencia"
    "C09:C09_vehiculos_mensajero:svc_centro"
    "C10:C10_estado_actual:svc_gerencia"
)

fallas=0
{
    printf '%-6s %-14s %s\n' "Id" "Cuenta" "Filas"
} > "$DESTINO/resumen.txt"

for item in "${CONSULTAS[@]}"; do
    IFS=: read -r id archivo cuenta <<< "$item"
    fecha="$(date '+%Y-%m-%d %H:%M:%S %Z')"
    salida="$("$EJECUTAR" "$cuenta" "queries/$archivo.sql" 2>&1)"
    codigo=$?
    # quita las lineas de preparacion de la sesion
    cuerpo="$(printf '%s\n' "$salida" | grep -v '^Session altered\.$' | sed '/./,$!d')"
    if [[ $codigo -eq 0 ]]; then
        if grep -q 'no rows selected' <<< "$cuerpo"; then
            filas=0
        else
            filas="$(grep -Eo '^[0-9]+ rows? selected' <<< "$cuerpo" | grep -Eo '^[0-9]+' | tail -1)"
        fi
        resultado="$filas"
    else
        fallas=$((fallas + 1))
        resultado="ERROR"
    fi
    {
        echo "Consulta: $id ($archivo.sql)"
        echo "Cuenta:   $cuenta (CURRENT_SCHEMA = BD_ENLACE_EXPRESS)"
        echo "Fecha:    $fecha"
        echo "Filas:    $resultado"
        echo
        printf '%s\n' "$cuerpo"
    } > "$DESTINO/$id.txt"
    printf '%-6s %-14s %s\n' "$id" "$cuenta" "$resultado" | tee -a "$DESTINO/resumen.txt"
done

# Consultas de apoyo (complementos.sql): explican los resultados de C6 a C9 en el documento
salida="$("$EJECUTAR" propietario "queries/complementos.sql" 2>&1)"
if [[ $? -eq 0 ]]; then
    {
        echo "Consultas de apoyo (complementos.sql), como propietario"
        echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        printf '%s\n' "$salida" | grep -v '^Session altered\.$' | sed '/./,$!d'
    } > "$DESTINO/complementos.txt"
    echo "Complementos guardados en complementos.txt"
else
    fallas=$((fallas + 1))
    printf '%s\n' "$salida" > "$DESTINO/complementos.txt"
fi

echo
if [[ $fallas -gt 0 ]]; then
    echo "Consultas con error: $fallas (ver docs/evidence/05_consultas/)" >&2
    exit 1
fi
echo "Las 10 consultas se ejecutaron sin errores."
