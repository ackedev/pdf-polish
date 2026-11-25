#!/usr/bin/env bash
# Uso: pick.sh [tema1,tema2,...]
# Imprime "tema paleta" evitando las últimas combinaciones y los últimos temas usados.
set -euo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
HIST="${HOME}/.cache/pdf-polish/history"
ALLOWED="${1:-}"

themes=($(ls "$DIR/themes" | sed 's/\.css//'))
palettes=($(grep -o 'data-palette="[a-z]*"' "$DIR/palettes/palettes.css" | sed 's/.*="\(.*\)"/\1/'))

[[ -n "$ALLOWED" ]] && IFS=',' read -r -a themes <<< "$ALLOWED"

last_themes=""; last_palettes=""
if [[ -f "$HIST" ]]; then
  last_themes="$(tail -n 2 "$HIST" | awk '{print $1}' | tr '\n' ' ')"
  last_palettes="$(tail -n 3 "$HIST" | awk '{print $2}' | tr '\n' ' ')"
fi

pool_t=(); for t in "${themes[@]}"; do [[ " $last_themes " == *" $t "* ]] || pool_t+=("$t"); done
[[ ${#pool_t[@]} -eq 0 ]] && pool_t=("${themes[@]}")
pool_p=(); for p in "${palettes[@]}"; do [[ " $last_palettes " == *" $p "* ]] || pool_p+=("$p"); done
[[ ${#pool_p[@]} -eq 0 ]] && pool_p=("${palettes[@]}")

echo "${pool_t[RANDOM % ${#pool_t[@]}]} ${pool_p[RANDOM % ${#pool_p[@]}]}"
