# How to design the cover illustration

Goal: an illustration that looks made **for that document**, with a clever but subtle detail.
Reference: `examples/cover-art/plant-circuit.svg` (report on the environmental impact of technology: a plant whose branches are circuit traces, born from a chip, with organic leaves, a flower of pads and pixels breaking away).

## 1. Find the idea (before drawing)
1. Summarize the document in one sentence: **what it is about** and **what its tension or thesis is**.
2. Pull out two worlds: the **topic** (plant, city, health, money, ocean…) and the **field** (technology, education, data…).
3. Merge both into **a single figure** where each part has a double reading. Examples of the technique:
   - ecology + technology → plant with a circuit stem
   - education + data → open book whose pages are bar charts shaped like leaves
   - health + AI → heart silhouette made of neural-network lines
   - finance + sustainability → stacked coins forming a trunk with rings
4. Choose **one** idea. If torn between two, the simpler one.

Subtlety: at first glance one simple image reads (a plant); the second meaning is discovered up close. No cliché icons (light bulb, gear, generic brain-chip, globe with wifi).

## 2. Drawing rules (inline SVG)
- `viewBox="0 0 400 500"` (vertical). No background, no text inside the SVG.
- **Colors only through variables**: `stroke="var(--art-1)"` (main stroke) and `var(--art-2)` (accent). That way it adapts to any theme and palette, even dark covers. Never fixed hex values.
- **Thin line** style (`stroke-width` 1.5-2.5, `stroke-linecap="round"`, `stroke-linejoin="round"`), `fill="none"`; fills only with `fill-opacity` .1-.25.
- Few elements: **10-25 shapes**. Vertical composition, with a clear axis, lots of air around.
- A single "surprise" detail (the pixels breaking away, the pad at the tip…), not five.
- Gently broken symmetry: avoid it looking like a template.
- Round coordinates and 45°/90° straight lines for the technical; smooth Bézier curves for the organic. The contrast between both = the concept.

## 3. Integrate
Inside `<section class="cover">`, before `.meta`:
```html
<div class="cover-art"><svg viewBox="0 0 400 500" …>…</svg></div>
```
The theme places and colors `.cover-art` (top or bottom corner, depending on each cover's design). Do not put positioning styles inline.

## 4. Verify
Render and look at page 1 (`pdf2png.swift`). Check:
- it does not cover the title, subtitle or meta;
- it stands out against the cover background (in `corporate`, `bold`, `mono` the lines are light);
- the idea is understood without explanation;
- nothing is cut off.
If something fails, fix and repeat (max 2 times). If the idea does not work visually, simplify it; do not add more elements.

## 5. Plan B
If no good metaphor comes out: an abstract composition (lines, circles, grids) with `--art-1/--art-2`, inspired by the topic (waves for water, grid for data, rings for time). Better sober than forced.
