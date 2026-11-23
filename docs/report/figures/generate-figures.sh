#!/usr/bin/env bash
# Regenera las figuras de la seccion 6.3 del documento:
#  - renderiza los diagramas UML de docs/diagrams/*.puml a PNG (PlantUML en Docker)
#  - copia las capturas de la aplicacion que usa la seccion desde docs/evidence/10_aplicacion/
# Uso:  docs/report/figures/generate-figures.sh
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DESTINO="$RAIZ/docs/report/figures"
DIAGRAMAS="$RAIZ/docs/diagrams"
CAPTURAS="$RAIZ/docs/evidence/10_aplicacion"
IMAGEN="plantuml/plantuml:1.2024.8"

# diagrama:figura
UML=(
    "casos_uso_modulo_envios:uml_casos_uso"
    "componentes_modulo_envios:uml_componentes"
    "clases_dominio:uml_clases_dominio"
    "clases_mapeadores:uml_clases_mapeadores"
)
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
for par in "${UML[@]}"; do
    origen="${par%%:*}"
    figura="${par##*:}"
    docker run --rm -u "$(id -u):$(id -g)" -v "$DIAGRAMAS":/data:ro -v "$TMP":/salida "$IMAGEN" \
        -tpng -o /salida "/data/$origen.puml"
    mv "$TMP/$origen.png" "$DESTINO/$figura.png"
    echo "UML: $figura.png"
done

# capturas usadas por la seccion 6.3.7
CAPTURAS_USADAS=(
    01_rastreo_publico
    04_mesa_registro_envio
    06_centro_recepcion
    07_centro_despacho_armado
    09_mensajero_planilla_movil
    10_rechazo_rn06_movil
    15_cliente_recorrido
    16_tablero
    18_mensajero_tercer_intento_movil
    21_rechazo_rn12_anular_entregado
    23_mesa_reclamacion_respondida
)
for c in "${CAPTURAS_USADAS[@]}"; do
    cp "$CAPTURAS/$c.png" "$DESTINO/$c.png"
    echo "Captura: $c.png"
done
