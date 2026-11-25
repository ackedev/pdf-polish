// Usage: swift pdf2text.swift input.pdf
// Extracts text from a PDF page by page (to use an existing PDF as a content source).
// Limitation: does not recover images or table structure; returns nothing for a scanned PDF.
import Foundation
import PDFKit

guard CommandLine.arguments.count >= 2, let doc = PDFDocument(url: URL(fileURLWithPath: CommandLine.arguments[1])) else {
    FileHandle.standardError.write("Usage: pdf2text.swift input.pdf\n".data(using: .utf8)!)
    exit(1)
}
for i in 0..<doc.pageCount {
    print("===== PÁGINA \(i + 1) =====")
    print(doc.page(at: i)?.string ?? "")
}
