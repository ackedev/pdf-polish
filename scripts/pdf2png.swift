// Uso: swift pdf2png.swift entrada.pdf carpeta_salida [escala]
// Exporta cada página del PDF a PNG (p1.png, p2.png, ...) usando PDFKit de macOS.
import Foundation
import PDFKit
import AppKit

let args = CommandLine.arguments
guard args.count >= 3, let doc = PDFDocument(url: URL(fileURLWithPath: args[1])) else {
    FileHandle.standardError.write("Uso: pdf2png.swift entrada.pdf carpeta_salida [escala]\n".data(using: .utf8)!)
    exit(1)
}
let scale = args.count > 3 ? CGFloat(Double(args[3]) ?? 1.0) : 1.0
try? FileManager.default.createDirectory(atPath: args[2], withIntermediateDirectories: true)
for i in 0..<doc.pageCount {
    guard let page = doc.page(at: i) else { continue }
    let box = page.bounds(for: .mediaBox)
    let size = NSSize(width: box.width * scale, height: box.height * scale)
    let img = page.thumbnail(of: size, for: .mediaBox)
    guard let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else { continue }
    try? png.write(to: URL(fileURLWithPath: "\(args[2])/p\(i + 1).png"))
}
print("OK: \(doc.pageCount) páginas")
