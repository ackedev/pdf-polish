#!/usr/bin/env bash
# Uso: render.sh --theme editorial --palette cobalt --in cuerpo.html --out salida.pdf
# Envuelve un fragmento HTML (el cuerpo) con CSS del tema y lo imprime a PDF con Chrome headless.
set -euo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
STATE_DIR="${HOME}/.cache/pdf-polish"
THEME=""; PALETTE=""; IN=""; OUT=""
ACCENT=""; ACCENT2=""; FONT_BODY=""; FONT_TITLE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --theme) THEME="$2"; shift 2;;
    --palette) PALETTE="$2"; shift 2;;
    --accent) ACCENT="$2"; shift 2;;          # color principal personalizado, p. ej. #d62828
    --accent2) ACCENT2="$2"; shift 2;;        # color secundario/oscuro personalizado, p. ej. #f77f00
    --font-body) FONT_BODY="$2"; shift 2;;    # fuente del texto, p. ej. "Georgia"
    --font-title) FONT_TITLE="$2"; shift 2;;  # fuente de los títulos, p. ej. "Futura"
    --in) IN="$2"; shift 2;;
    --out) OUT="$2"; shift 2;;
    *) echo "Argumento desconocido: $1" >&2; exit 1;;
  esac
done

# Con colores propios no hace falta paleta: se usa "custom" (el valor solo queda en el historial)
[[ -z "$PALETTE" && -n "$ACCENT" ]] && PALETTE="custom"

[[ -f "$DIR/themes/$THEME.css" ]] || { echo "Tema no válido: '$THEME'. Disponibles: $(ls "$DIR/themes" | sed 's/\.css//' | tr '\n' ' ')" >&2; exit 1; }
if [[ "$PALETTE" != "custom" ]]; then
  grep -q "data-palette=\"$PALETTE\"" "$DIR/palettes/palettes.css" || { echo "Paleta no válida: '$PALETTE'" >&2; exit 1; }
fi
HEX='^#[0-9a-fA-F]{6}$'
for c in "$ACCENT" "$ACCENT2"; do
  [[ -z "$c" || "$c" =~ $HEX ]] || { echo "Color no válido: '$c' (usa formato #rrggbb)" >&2; exit 1; }
done
[[ -z "$ACCENT2" || -n "$ACCENT" ]] || { echo "--accent2 requiere --accent" >&2; exit 1; }
for f in "$FONT_BODY" "$FONT_TITLE"; do
  [[ -z "$f" || "$f" =~ ^[A-Za-z0-9\ \-]+$ ]] || { echo "Nombre de fuente no válido: '$f'" >&2; exit 1; }
  if [[ -n "$f" ]] && command -v swift >/dev/null; then
    swift "$DIR/scripts/hasfont.swift" "$f" >&2 || echo "AVISO: la fuente '$f' no está instalada; Chrome usará una de respaldo." >&2
  fi
done

# CSS de personalización (mayor especificidad que tema y paleta)
OVERRIDE=""
if [[ -n "$ACCENT" ]]; then
  A2="${ACCENT2:-$(printf '#%02x%02x%02x' $(( 16#${ACCENT:1:2} * 35 / 100 )) $(( 16#${ACCENT:3:2} * 35 / 100 )) $(( 16#${ACCENT:5:2} * 35 / 100 )))}"
  OVERRIDE+="html[data-theme][data-palette]{--accent:$ACCENT;--accent-2:$A2;--tint:color-mix(in srgb,$ACCENT 10%,white);}"
fi
[[ -n "$FONT_BODY" ]]  && OVERRIDE+="html[data-theme][data-palette]{--font-body:\"$FONT_BODY\",sans-serif;}"
[[ -n "$FONT_TITLE" ]] && OVERRIDE+="html[data-theme][data-palette]{--font-head:\"$FONT_TITLE\",serif;}"
[[ -f "$IN" ]] || { echo "No existe el fichero de entrada: $IN" >&2; exit 1; }
[[ -n "$OUT" ]] || { echo "Falta --out" >&2; exit 1; }

CHROME=""
for c in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
         "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" \
         "/Applications/Chromium.app/Contents/MacOS/Chromium"; do
  [[ -x "$c" ]] && CHROME="$c" && break
done
[[ -n "$CHROME" ]] || { echo "No encuentro Chrome, Brave ni Chromium." >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
{
  # Los atributos van en <html> para que el fondo del tema cubra toda la página, márgenes incluidos
  echo "<!doctype html><html lang=\"es\" data-theme=\"$THEME\" data-palette=\"$PALETTE\"><head><meta charset=\"utf-8\"><style>"
  cat "$DIR/base.css" "$DIR/themes/$THEME.css" "$DIR/palettes/palettes.css"
  echo "$OVERRIDE"
  echo "</style></head><body>"
  cat "$IN"
  echo '</body></html>'
} > "$WORK/doc.html"

rm -f "$OUT"
# Perfil temporal para no chocar con un Chrome ya abierto.
# Chrome a veces no se cierra solo tras imprimir: lo lanzamos en segundo plano,
# esperamos a que el PDF exista y deje de crecer, y lo cerramos nosotros.
"$CHROME" --headless=new --disable-gpu --no-sandbox --user-data-dir="$WORK/profile" \
  --no-pdf-header-footer --run-all-compositor-stages-before-draw \
  --print-to-pdf="$OUT" "file://$WORK/doc.html" >/dev/null 2>&1 &
CPID=$!

prev=-1
for _ in $(seq 1 60); do            # máx. ~30 s
  sleep 0.5
  if [[ -s "$OUT" ]]; then
    size=$(stat -f%z "$OUT")
    [[ "$size" == "$prev" ]] && break
    prev=$size
  fi
done
kill "$CPID" 2>/dev/null || true
pkill -f "user-data-dir=$WORK/profile" 2>/dev/null || true
wait "$CPID" 2>/dev/null || true

[[ -s "$OUT" ]] || { echo "Chrome no generó el PDF." >&2; exit 1; }

# Recordar la combinación usada para no repetirla en el siguiente PDF
mkdir -p "$STATE_DIR"
echo "$THEME $PALETTE" >> "$STATE_DIR/history"
tail -n 20 "$STATE_DIR/history" > "$STATE_DIR/history.tmp" && mv "$STATE_DIR/history.tmp" "$STATE_DIR/history"

echo "OK: $OUT ($THEME / $PALETTE)"
