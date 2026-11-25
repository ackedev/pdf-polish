---
name: pdf-polish
description: Turns already-written content (a PDF, markdown, text, notes, a report) into a professionally designed, varied PDF, with an optional custom illustrated cover. Use it when the user says "apply the pdf-polish skill" / "aplica la skill pdf-polish", asks for a "nicer", "better presented" or "differently designed" PDF ("PDF bonito", "mejor presentado", "con otro diseño"), or complains that PDFs always look the same. Accepts a custom body font, title font and colors. Asks few questions and does the rest on its own. Does not change the content, only the presentation.
---

# pdf-polish

The content is already good; this skill decides **how it looks**, avoids repeating the same design, checks that no big blank gaps remain and, if a cover is wanted, designs one tailored to the document's topic.
Render: HTML + CSS → PDF with headless Chrome (macOS; nothing to install, system fonts only).

**Language:** talk to the user in the language they write in (questions, explanations, delivery message). The document's own language is never changed.

Paths: everything lives in `~/.claude/skills/pdf-polish/` (abbreviated `$S` below).

## What the user can ask for (all optional)

Example: *"Apply the pdf-polish skill to this PDF, Georgia font, titles in Futura, red and orange colors, with a cover"*.

| Request | What to do |
|---|---|
| Body font | `--font-body "Name"` |
| Title font | `--font-title "Name"` |
| Colors ("red and orange", "dark green", a hex) | `--accent #hex --accent2 #hex` (see «Colors») |
| A specific theme ("editorial style") | `--theme name` instead of the rotation |
| Cover yes/no | See step 4 |

Whatever the user does **not** specify, you decide with the `pick.sh` rotation.

## Flow

### 1. Read the content (do not edit it)
- If the source is a **PDF**: look at its structure with the PDF reading tool and extract the exact text with
  `swift $S/scripts/pdf2text.swift source.pdf`. The original's images are not recovered: ask whether they must be kept (and where to get them). If no text comes out, it is a scan: warn the user.
- If it is markdown/text: read it in full.
- Do not rewrite, summarize or change the text. Only fix obvious formatting (broken lists, badly nested headings). If you spot a content error, point it out; do not silently fix it.

### 2. Ask (at most 3, in a single message, with options and a default)
Skip whatever the user already said or what can be deduced.
1. **What it is for**: class assignment / formal report / proposal or pitch / technical documentation / personal.
2. **Tone**: sober, editorial/elegant, modern and clean, bold.
3. **Cover**: yes or no (default yes for documents of 3+ pages).

If they say "you decide", ask nothing more.

### 3. Choose the design

| Use / tone | Candidate themes |
|---|---|
| Essay, thesis, narrative, elegant | `editorial` |
| Data, proposal, technical report, clean | `swiss` |
| Business, formal submission, sober | `corporate` |
| Pitch, portfolio, guide, visual and bold | `bold` |
| Code, technical documentation, dev | `mono` |

```bash
bash $S/scripts/pick.sh editorial,swiss     # → "theme palette"
```

It returns `theme palette`, avoiding what was used in the latest PDFs. **Respect it**: that is what prevents repeated designs. Ignore it only if the user fixed a theme or colors.

#### Custom colors
- `--accent` is the main color (accent headings, figures, bands). `--accent2` is the **dark** tone (`corporate` cover backgrounds, gradients); if you do not give it, a dark version of the accent is computed.
- Translate color names to hex with design judgment, not literally: "red and orange" → `--accent #e85d04 --accent2 #9d0208` (vivid orange + dark red). Do not let the dark tone be light: the white text on `corporate`, `bold` and `mono` covers would lose contrast.
- With custom colors do not use `--palette`.

#### Fonts
- Only fonts installed on the Mac work. `render.sh` warns if one is missing and suggests similar ones (`swift $S/scripts/hasfont.swift "Name"`). If it is not there, propose the closest one instead of silently continuing with a fallback.
- Safe fonts: Palatino, Baskerville, Georgia, Didot, Avenir Next, Futura, Optima, Gill Sans, Helvetica Neue, Menlo.

### 4. Cover
Only if the user wants it. Structure:

```html
<section class="cover">
  <div class="band"></div>                 <!-- essential in corporate; harmless in the rest -->
  <h1 class="title">Title</h1>
  <p class="subtitle">Subtitle</p>
  <div class="cover-art"> <svg viewBox="0 0 400 500" …> … </svg> </div>   <!-- custom illustration -->
  <p class="meta">Author · Date</p>
</section>
```

**You design the illustration for this document; do not copy a generic one.** Follow `cover-art.md` (read it before drawing). Summary: find the document's central concept, merge two worlds into a single subtle visual metaphor (e.g. a report on the environmental impact of technology → a plant whose stem is circuit traces, with leaves and a flower made of pads). Full example in `examples/cover-art/plant-circuit.svg`.

If no good metaphor comes to mind, make an abstract geometric composition with the theme's colors rather than a cliché icon.

### 5. Write the HTML body
A `.html` file with **only the contents of `<body>`**. Available classes:

- `h1`, `h2`, `h3`, `p`, `ul/ol`, `table`, `blockquote`, `pre><code`
- `<p class="lead">` highlighted first paragraph of a section
- `<div class="callout"><span class="label">Note</span><p>…</p></div>`
- `<div class="stats"><div class="stat"><span class="num">42%</span><span class="cap">…</span></div>…</div>` (3-4 max.)
- `<div class="cols">` two text columns; `<div class="grid-2">` two blocks side by side
- `<figure><img src="/absolute/path.png"><figcaption>…</figcaption></figure>`
- `<div class="pagebreak"></div>` forced break; `class="avoid-break"` to not split a block

Criteria (they affect design, not text): a single cover; no stats/callouts/columns just for decoration; tables of 5-6 columns max; **use `pagebreak` as little as possible** (each one risks a half-empty page).

### 6. Render

```bash
bash $S/scripts/render.sh --theme <theme> --palette <palette> --in body.html --out output.pdf
# with customization:
bash $S/scripts/render.sh --theme bold --accent "#e85d04" --accent2 "#9d0208" \
  --font-body "Georgia" --font-title "Futura" --in body.html --out output.pdf
```

### 7. Mandatory review (blank gaps and design)

**a) Blank gaps.** Run:
```bash
swift $S/scripts/check_layout.swift output.pdf --cover     # without --cover if there is no cover
```
It prints per page: words, how far the content reaches and the largest internal gap. It ends in `RESULT: OK` or `RESULT: REVIEW`.
If it says `REVIEW`, **do not deliver**. Diagnose with the cause each `WARN` gives:
- Page ending at <70%: a block (table, figure, callout, `.avoid-break`) did not fit and moved whole. Remove `avoid-break`, split the table in two, shrink the figure or reorder.
- Empty page or a single sentence: a `pagebreak` is extra. Remove it.
- Internal gap ≥22%: figure with no height, huge margins or empty elements.
- Density <150 words/page in a text document: too much air; reduce breaks and spacing.
- Last page with almost nothing: adjust so it fits on the previous one.
Note: a short page at the end of a section is normal; act when it is systematic or obvious. Re-render and check again (max. 3 iterations; if it persists, say so on delivery).

**b) Visual review.** Export and look at all pages:
```bash
swift $S/scripts/pdf2png.swift output.pdf /temp/path/pages 1     # p1.png, p2.png…
```
Look for: cover (cut-off text, illustration covering the title or misplaced, contrast), orphaned headings at the bottom of a page, cut tables, overflowing text.

### 8. Deliver
2-3 lines: PDF path, theme/palette/fonts chosen and why, and what illustration was made for the cover and what it represents. Offer to change theme, color or font (just repeat `render.sh`).

## Notes
- Combination history: `~/.cache/pdf-polish/history` (last 20). Deleting it restarts the rotation.
- New theme: copy a `.css` from `themes/`, change the `[data-theme="…"]` selector; include the `.cover-art` rules and the cover's `--art-1/--art-2` variables. `pick.sh` detects it on its own.
- New palette: one line in `palettes/palettes.css`.
- If Chrome fails: Chrome, Brave or Chromium must be in `/Applications`.
