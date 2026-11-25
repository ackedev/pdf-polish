# Cómo diseñar la ilustración de portada

Objetivo: una ilustración que parezca hecha **para ese documento**, con un detalle ingenioso pero sutil.
Referencia: `examples/cover-art/plant-circuit.svg` (informe sobre el impacto ecológico de la tecnología: una planta cuyas ramas son pistas de circuito, nacida de un chip, con hojas orgánicas, una flor de pads y píxeles que se desprenden).

## 1. Encontrar la idea (antes de dibujar)
1. Resume el documento en una frase: **de qué trata** y **cuál es su tensión o tesis**.
2. Saca dos mundos: el **tema** (planta, ciudad, salud, dinero, océano…) y el **ámbito** (tecnología, educación, datos…).
3. Funde ambos en **una sola figura** donde cada parte tenga doble lectura. Ejemplos de la técnica:
   - ecología + tecnología → planta con tallo de circuito
   - educación + datos → libro abierto cuyas páginas son gráficas de barras en forma de hojas
   - salud + IA → silueta de corazón hecha con líneas de red neuronal
   - finanzas + sostenibilidad → monedas apiladas que forman un tronco con anillos
4. Elige **una** idea. Si dudas entre dos, la más simple.

Sutileza: a primera vista se lee una imagen simple (una planta); el segundo significado se descubre al mirar de cerca. Nada de iconos tópicos (bombilla, engranaje, cerebro-chip genérico, globo con wifi).

## 2. Reglas de dibujo (SVG en línea)
- `viewBox="0 0 400 500"` (vertical). Sin fondo, sin texto dentro del SVG.
- **Solo colores por variables**: `stroke="var(--art-1)"` (trazo principal) y `var(--art-2)` (acento). Así se adapta a cualquier tema y paleta, incluso a portadas oscuras. Nunca hex fijos.
- Estilo **línea fina** (`stroke-width` 1.5-2.5, `stroke-linecap="round"`, `stroke-linejoin="round"`), `fill="none"`; rellenos solo con `fill-opacity` .1-.25.
- Pocos elementos: **10-25 formas**. Composición vertical, con un eje claro, mucho aire alrededor.
- Un solo detalle de "sorpresa" (los píxeles que se desprenden, el pad en la punta…), no cinco.
- Simetría rota suave: evita que parezca una plantilla.
- Coordenadas redondas y rectas a 45°/90° para lo técnico; curvas Bézier suaves para lo orgánico. Contraste entre ambos = el concepto.

## 3. Integrar
Dentro de `<section class="cover">`, antes de `.meta`:
```html
<div class="cover-art"><svg viewBox="0 0 400 500" …>…</svg></div>
```
El tema coloca y colorea `.cover-art` (esquina superior o inferior, según el diseño de cada portada). No pongas estilos en línea de posición.

## 4. Verificar
Renderiza y mira la página 1 (`pdf2png.swift`). Comprueba:
- no tapa título, subtítulo ni meta;
- se distingue sobre el fondo de la portada (en `corporate`, `bold`, `mono` las líneas son claras);
- la idea se entiende sin explicación;
- no hay nada cortado.
Si algo falla, corrige y repite (máx. 2 veces). Si la idea no funciona visualmente, simplifícala; no añadas más elementos.

## 5. Plan B
Si no sale una metáfora buena: composición abstracta (líneas, círculos, cuadrículas) con `--art-1/--art-2`, inspirada en el tema (ondas para agua, retícula para datos, anillos para tiempo). Mejor sobria que forzada.
