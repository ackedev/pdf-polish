// Uso: swift check_layout.swift salida.pdf [--cover]
// Detecta huecos en blanco anormales. Por página imprime: palabras, % de página ocupada y hueco interno más grande.
// Con --cover se ignora la página 1 (portada). Termina con "RESULT: OK" o "RESULT: REVISAR" y líneas WARN con la causa probable.
import Foundation
import PDFKit
import AppKit

let args = CommandLine.arguments
guard args.count >= 2, let doc = PDFDocument(url: URL(fileURLWithPath: args[1])) else {
    FileHandle.standardError.write("Uso: check_layout.swift entrada.pdf [--cover]\n".data(using: .utf8)!)
    exit(1)
}
let hasCover = args.contains("--cover")
let n = doc.pageCount
var warns: [String] = []
var bodyWords = 0
var bodyPages = 0

print("Páginas: \(n)")
for i in 0..<n {
    guard let page = doc.page(at: i) else { continue }
    let words = (page.string ?? "").split(whereSeparator: { $0.isWhitespace }).count
    let isCover = hasCover && i == 0
    let isLast = i == n - 1

    let box = page.bounds(for: .mediaBox)
    let scale: CGFloat = 0.4
    let size = NSSize(width: box.width * scale, height: box.height * scale)
    let img = page.thumbnail(of: size, for: .mediaBox)
    guard let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let data = rep.bitmapData else { continue }
    let w = rep.pixelsWide, h = rep.pixelsHigh, spp = rep.samplesPerPixel, bpr = rep.bytesPerRow

    // Color de fondo = píxel de la esquina superior izquierda
    let bg = (0..<min(3, spp)).map { Int(data[$0]) }
    func rowHasInk(_ y: Int) -> Bool {
        var x = 0
        while x < w {
            let o = y * bpr + x * spp
            for c in 0..<min(3, spp) where abs(Int(data[o + c]) - bg[c]) > 14 { return true }
            x += 2
        }
        return false
    }

    let footerStart = Int(Double(h) * 0.90)       // ignora el número de página
    var first = -1, last = -1
    var inkRows = [Bool](repeating: false, count: footerStart)
    for y in 0..<footerStart { if rowHasInk(y) { inkRows[y] = true; if first < 0 { first = y }; last = y } }

    // Hueco interno más grande entre primera y última fila con contenido
    var maxGap = 0, run = 0
    if first >= 0 { for y in first...last { if inkRows[y] { maxGap = max(maxGap, run); run = 0 } else { run += 1 } } }
    let fill = first < 0 ? 0 : Int(round(Double(last) / Double(footerStart) * 100))
    let gapPct = Int(round(Double(maxGap) / Double(h) * 100))
    print("  p\(i + 1): \(words) palabras · ocupa hasta \(fill)% · hueco interno máx \(gapPct)%\(isCover ? " · portada (ignorada)" : "")")

    if isCover { continue }
    bodyWords += words
    bodyPages += 1
    if first < 0 && !isLast { warns.append("p\(i + 1) está VACÍA. Causa probable: un salto de página forzado extra o un bloque con avoid-break que no cabe.") }
    else if fill < 70 && !isLast { warns.append("p\(i + 1) solo se llena hasta el \(fill)%: el siguiente bloque se movió entero a la página siguiente (tabla, figura, callout, .avoid-break o .pagebreak).") }
    if gapPct >= 22 { warns.append("p\(i + 1) tiene un hueco interno del \(gapPct)% de la altura: revisa márgenes enormes, figuras sin altura o elementos vacíos.") }
    if isLast && words < 25 && n > 2 && !(hasCover && n == 2) { warns.append("p\(n) (última) casi no tiene texto (\(words) palabras): una página casi vacía al final. Ajusta tamaños o márgenes para recoger ese contenido en la anterior.") }
}

// Densidad global: un documento normal da 300-500 palabras por página con texto corrido
if bodyPages >= 3 {
    let avg = bodyWords / bodyPages
    print("Media: \(avg) palabras/página de contenido")
    if avg < 150 { warns.append("Densidad muy baja (\(avg) palabras/página): probablemente demasiado aire (saltos de página, espaciados grandes) o contenido muy visual. Si el contenido es texto, hay páginas de más.") }
}

for w in warns { print("WARN: \(w)") }
print(warns.isEmpty ? "RESULT: OK" : "RESULT: REVISAR")
