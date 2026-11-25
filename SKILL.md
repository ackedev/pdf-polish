---
name: pdf-polish
description: Convierte contenido ya escrito (un PDF, markdown, texto, notas, un informe) en un PDF con diseño profesional y variado, con portada ilustrada a medida opcional. Úsala cuando el usuario diga "aplica la skill pdf-polish", pida un PDF "bonito", "mejor presentado" o "con otro diseño", o se queje de que los PDFs siempre salen con el mismo aspecto. Acepta fuente, colores y fuente de títulos personalizados. Hace pocas preguntas y el resto lo hace sola. No cambia el contenido, solo la presentación.
---

# pdf-polish

El contenido ya está bien; esta skill decide **cómo se ve**, evita repetir diseño, comprueba que no queden huecos en blanco y, si se quiere portada, la diseña a medida del tema del documento.
Render: HTML + CSS → PDF con Chrome headless (macOS; sin instalar nada, solo fuentes del sistema).

Rutas: todo está en `~/.claude/skills/pdf-polish/` (abreviado `$S` abajo).

## Qué puede pedir el usuario (todo opcional)

Ejemplo: *"Aplica la skill pdf-polish a este PDF, fuente Georgia, títulos en Futura, colores rojo y naranja, con portada"*.

| Petición | Qué hacer |
|---|---|
| Fuente del texto | `--font-body "Nombre"` |
| Fuente de títulos | `--font-title "Nombre"` |
| Colores ("rojo y naranja", "verde oscuro", un hex) | `--accent #hex --accent2 #hex` (ver «Colores») |
| Tema concreto ("estilo editorial") | `--theme nombre` en vez de la rotación |
| Portada sí/no | Ver paso 4 |

Lo que **no** pida el usuario lo decides tú con la rotación de `pick.sh`.

## Flujo

### 1. Leer el contenido (no editarlo)
- Si la fuente es un **PDF**: mira su estructura con la herramienta de lectura de PDF y extrae el texto exacto con
  `swift $S/scripts/pdf2text.swift origen.pdf`. Las imágenes del original no se recuperan: pregunta si hay que conservarlas (y de dónde sacarlas). Si no sale texto, es un escaneo: avisa.
- Si es markdown/texto: léelo completo.
- No reescribas, resumas ni cambies el texto. Solo arregla formato evidente (listas rotas, títulos mal anidados). Si ves un error de contenido, avisa; no lo corrijas en silencio.

### 2. Preguntar (máximo 3, en un solo mensaje, con opciones y una por defecto)
Salta lo que el usuario ya haya dicho o se deduzca.
1. **Para qué es**: entrega de clase / informe formal / propuesta o pitch / documentación técnica / personal.
2. **Tono**: sobrio, editorial/elegante, moderno y limpio, atrevido.
3. **Portada**: sí o no (por defecto sí en documentos de 3+ páginas).

Si dice "tú decide", no preguntes más.

### 3. Elegir diseño

| Uso / tono | Temas candidatos |
|---|---|
| Ensayo, memoria, narrativo, elegante | `editorial` |
| Datos, propuesta, informe técnico, limpio | `swiss` |
| Empresa, entrega formal, sobrio | `corporate` |
| Pitch, portfolio, guía, visual y atrevido | `bold` |
| Código, documentación técnica, DAM | `mono` |

```bash
bash $S/scripts/pick.sh editorial,swiss     # → "tema paleta"
```

Devuelve `tema paleta` evitando lo usado en los últimos PDFs. **Respétalo**: es lo que evita el diseño repetido. Solo lo ignoras si el usuario fijó tema o colores.

#### Colores personalizados
- `--accent` es el color principal (títulos de acento, cifras, bandas). `--accent2` es el tono **oscuro** (fondos de portada `corporate`, degradados); si no lo das, se calcula un oscuro del accent.
- Traduce nombres a hex con criterio de diseño, no literal: "rojo y naranja" → `--accent #e85d04 --accent2 #9d0208` (naranja vivo + rojo oscuro). Evita que el tono oscuro sea claro: el texto blanco de portadas `corporate`, `bold` y `mono` perdería contraste.
- Con colores propios no uses `--palette`.

#### Fuentes
- Solo valen fuentes instaladas en el Mac. `render.sh` avisa si no existe y sugiere parecidas (`swift $S/scripts/hasfont.swift "Nombre"`). Si no está, propón la más cercana en vez de seguir con una de respaldo sin avisar.
- Fuentes seguras: Palatino, Baskerville, Georgia, Didot, Avenir Next, Futura, Optima, Gill Sans, Helvetica Neue, Menlo.

### 4. Portada
Solo si el usuario la quiere. Estructura:

```html
<section class="cover">
  <div class="band"></div>                 <!-- imprescindible en corporate; inofensivo en el resto -->
  <h1 class="title">Título</h1>
  <p class="subtitle">Subtítulo</p>
  <div class="cover-art"> <svg viewBox="0 0 400 500" …> … </svg> </div>   <!-- ilustración a medida -->
  <p class="meta">Autor · Fecha</p>
</section>
```

**La ilustración la diseñas tú para este documento, no copias una genérica.** Sigue `cover-art.md` (léelo antes de dibujar). Resumen: busca el concepto central del documento, funde dos mundos en una sola metáfora visual sutil (p. ej. informe sobre el impacto ecológico de la tecnología → una planta cuyo tallo son pistas de circuito, con hojas y flor hechas de pads). Ejemplo completo en `examples/cover-art/plant-circuit.svg`.

Si no se te ocurre una metáfora buena, haz una composición geométrica abstracta con los colores del tema antes que un icono tópico.

### 5. Escribir el cuerpo HTML
Fichero `.html` con **solo el contenido del `<body>`**. Clases disponibles:

- `h1`, `h2`, `h3`, `p`, `ul/ol`, `table`, `blockquote`, `pre><code`
- `<p class="lead">` primer párrafo destacado de una sección
- `<div class="callout"><span class="label">Nota</span><p>…</p></div>`
- `<div class="stats"><div class="stat"><span class="num">42%</span><span class="cap">…</span></div>…</div>` (3-4 máx.)
- `<div class="cols">` dos columnas de texto; `<div class="grid-2">` dos bloques lado a lado
- `<figure><img src="/ruta/absoluta.png"><figcaption>…</figcaption></figure>`
- `<div class="pagebreak"></div>` salto forzado; `class="avoid-break"` para no partir un bloque

Criterio (afecta al diseño, no al texto): una sola portada; nada de stats/callouts/columnas solo por decorar; tablas de máx. 5-6 columnas; **usa `pagebreak` lo mínimo** (cada uno es un riesgo de página medio vacía).

### 6. Renderizar

```bash
bash $S/scripts/render.sh --theme <tema> --palette <paleta> --in cuerpo.html --out salida.pdf
# con personalización:
bash $S/scripts/render.sh --theme bold --accent "#e85d04" --accent2 "#9d0208" \
  --font-body "Georgia" --font-title "Futura" --in cuerpo.html --out salida.pdf
```

### 7. Revisión obligatoria (huecos en blanco y diseño)

**a) Huecos en blanco.** Ejecuta:
```bash
swift $S/scripts/check_layout.swift salida.pdf --cover     # sin --cover si no hay portada
```
Imprime por página: palabras, hasta dónde llega el contenido y el hueco interno mayor. Termina en `RESULT: OK` o `RESULT: REVISAR`.
Si sale `REVISAR`, **no entregues**. Diagnostica con la causa que indica cada `WARN`:
- Página que acaba al <70%: un bloque (tabla, figura, callout, `.avoid-break`) no cabía y saltó entero. Quita `avoid-break`, parte la tabla en dos, reduce la figura o reordena.
- Página vacía o con una frase: sobra un `pagebreak`. Quítalo.
- Hueco interno ≥22%: figura sin alto, márgenes enormes o elementos vacíos.
- Densidad <150 palabras/página en un documento de texto: hay demasiado aire; reduce saltos y espaciados.
- Última página con casi nada: ajusta para que quepa en la anterior.
Ojo: un final de sección con página corta es normal; actúa cuando sea sistemático o evidente. Re-renderiza y vuelve a comprobar (máx. 3 iteraciones; si persiste, dilo en la entrega).

**b) Revisión visual.** Exporta y mira todas las páginas:
```bash
swift $S/scripts/pdf2png.swift salida.pdf /ruta/temporal/paginas 1     # p1.png, p2.png…
```
Busca: portada (texto cortado, ilustración tapando el título o fuera de sitio, contraste), títulos huérfanos al final de página, tablas cortadas, texto desbordado.

### 8. Entregar
2-3 líneas: ruta del PDF, tema/paleta/fuentes elegidos y por qué, y qué ilustración se hizo en la portada y qué representa. Ofrece cambiar tema, color o fuente (solo repetir `render.sh`).

## Notas
- Historial de combinaciones: `~/.cache/pdf-polish/history` (últimas 20). Borrarlo reinicia la rotación.
- Nuevo tema: copia un `.css` de `themes/`, cambia el selector `[data-theme="…"]`; incluye las reglas `.cover-art` y las variables `--art-1/--art-2` de la portada. `pick.sh` lo detecta solo.
- Nueva paleta: una línea en `palettes/palettes.css`.
- Si falla Chrome: debe haber Chrome, Brave o Chromium en `/Applications`.
