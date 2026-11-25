// Usage: swift hasfont.swift "Font name"
// Says whether the font is installed on macOS; if not, suggests similar names.
import Foundation
import AppKit

guard CommandLine.arguments.count >= 2 else { print("Usage: hasfont.swift \"Font\""); exit(1) }
let wanted = CommandLine.arguments[1]
let families = NSFontManager.shared.availableFontFamilies
if families.contains(where: { $0.caseInsensitiveCompare(wanted) == .orderedSame }) {
    print("OK: \(wanted)")
} else {
    let key = wanted.lowercased().split(separator: " ").first.map(String.init) ?? wanted.lowercased()
    let similar = families.filter { $0.lowercased().contains(key) }.prefix(6)
    print("MISSING: \(wanted)" + (similar.isEmpty ? "" : " · similar: " + similar.joined(separator: ", ")))
    exit(2)
}
