#!/usr/bin/env bash
# Comprueba que el SQL de database/queries/C01..C10 es identico, caracter por
# caracter, al de los 10 lstlisting del documento (docs/reference/06-desarrollo-proyecto.tex).
# Del archivo .sql se descartan comentarios (--), lineas SET, COLUMN y PROMPT,
# lineas en blanco y el ';' final. Termina con error si alguna es DISTINTO.
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEX="$RAIZ/docs/reference/06-desarrollo-proyecto.tex"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Extrae cada lstlisting sqlpro a $TMP/doc_NN.sql
awk -v dir="$TMP" '
    /^\\begin\{lstlisting\}\[style=sqlpro\]/ { n++; dentro = 1; archivo = sprintf("%s/doc_%02d.sql", dir, n); next }
    /^\\end\{lstlisting\}/ { dentro = 0; next }
    dentro { print > archivo }
' "$TEX"

total="$(ls "$TMP"/doc_*.sql | wc -l)"
if [[ "$total" -ne 10 ]]; then
    echo "Se esperaban 10 lstlisting y se encontraron $total" >&2
    exit 2
fi

archivos=("$RAIZ"/database/queries/C[0-9][0-9]_*.sql)
if [[ "${#archivos[@]}" -ne 10 ]]; then
    echo "Se esperaban 10 archivos C01..C10 y hay ${#archivos[@]}" >&2
    exit 2
fi

distintas=0
n=0
for f in "${archivos[@]}"; do
    n=$((n + 1))
    nn="$(printf '%02d' "$n")"
    # cuerpo SQL: sin comentarios, SET, COLUMN, PROMPT ni lineas vacias; sin ';' final
    grep -Ev '^(--|SET |COLUMN |PROMPT |[[:space:]]*$)' "$f" \
        | sed '$ s/;[[:space:]]*$//' > "$TMP/arch_$nn.sql"
    if diff -q "$TMP/doc_$nn.sql" "$TMP/arch_$nn.sql" > /dev/null; then
        printf 'C%s  IGUAL    %s\n' "$nn" "$(basename "$f")"
    else
        printf 'C%s  DISTINTO %s\n' "$nn" "$(basename "$f")"
        diff "$TMP/doc_$nn.sql" "$TMP/arch_$nn.sql" | head -10 || true
        distintas=$((distintas + 1))
    fi
done
echo
echo "$((10 - distintas)) IGUAL, $distintas DISTINTO"
[[ "$distintas" -eq 0 ]]
