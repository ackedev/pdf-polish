// Usage: swift check_layout.swift output.pdf [--cover]
// Detects abnormal blank gaps. Per page it prints: words, % of the page filled and largest internal gap.
// With --cover page 1 (cover) is ignored. Ends with "RESULT: OK" or "RESULT: REVIEW" and WARN lines with the cause probable.
import Foundation
import PDFKit
import AppKit

let args = CommandLine.arguments
guard args.count >= 2, let doc = PDFDocument(url: URL(fileURLWithPath: args[1])) else {
    FileHandle.standardError.write("Usage: check_layout.swift input.pdf [--cover]\n".data(using: .utf8)!)
    exit(1)
}
let hasCover = args.contains("--cover")
let n = doc.pageCount
var warns: [String] = []
var bodyWords = 0
var bodyPages = 0

print("Pages: \(n)")
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

    // Background color = top-left corner pixel
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

    let footerStart = Int(Double(h) * 0.90)       // ignores the page number
    var first = -1, last = -1
    var inkRows = [Bool](repeating: false, count: footerStart)
    for y in 0..<footerStart { if rowHasInk(y) { inkRows[y] = true; if first < 0 { first = y }; last = y } }

    // Largest internal gap between the first and last row with content
    var maxGap = 0, run = 0
    if first >= 0 { for y in first...last { if inkRows[y] { maxGap = max(maxGap, run); run = 0 } else { run += 1 } } }
    let fill = first < 0 ? 0 : Int(round(Double(last) / Double(footerStart) * 100))
    let gapPct = Int(round(Double(maxGap) / Double(h) * 100))
    print("  p\(i + 1): \(words) words · filled up to \(fill)% · largest internal gap \(gapPct)%\(isCover ? " · cover (ignored)" : "")")

    if isCover { continue }
    bodyWords += words
    bodyPages += 1
    if first < 0 && !isLast { warns.append("p\(i + 1) is EMPTY. Likely cause: an extra forced page break or an avoid-break block that does not fit.") }
    else if fill < 70 && !isLast { warns.append("p\(i + 1) is only filled up to \(fill)%: the next block moved whole to the next page (table, figure, callout, .avoid-break or .pagebreak).") }
    if gapPct >= 22 { warns.append("p\(i + 1) has an internal gap of \(gapPct)% of the height: check for huge margins, figures with no height or empty elements.") }
    if isLast && words < 25 && n > 2 && !(hasCover && n == 2) { warns.append("p\(n) (last) has almost no text (\(words) words): an almost empty page at the end. Adjust sizes or margins to fit that content on the previous page.") }
}

// Overall density: a normal document gives 300-500 words per page with running text
if bodyPages >= 3 {
    let avg = bodyWords / bodyPages
    print("Average: \(avg) words/page of content")
    if avg < 150 { warns.append("Very low density (\(avg) words/page): probably too much white space (page breaks, large spacing) or very visual content. If the content is text, there are too many pages.") }
}

for w in warns { print("WARN: \(w)") }
print(warns.isEmpty ? "RESULT: OK" : "RESULT: REVIEW")
