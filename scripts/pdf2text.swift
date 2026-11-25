// Uso: swift pdf2text.swift entrada.pdf
// Extrae el texto de un PDF página a página (para usar un PDF existente como fuente de contenido).
// Limitación: no recupera imágenes ni la estructura de tablas; en un PDF escaneado no devuelve nada.
import Foundation
import PDFKit

guard CommandLine.arguments.count >= 2, let doc = PDFDocument(url: URL(fileURLWithPath: CommandLine.arguments[1])) else {
    FileHandle.standardError.write("Uso: pdf2text.swift entrada.pdf\n".data(using: .utf8)!)
    exit(1)
}
for i in 0..<doc.pageCount {
    print("===== PÁGINA \(i + 1) =====")
    print(doc.page(at: i)?.string ?? "")
}
