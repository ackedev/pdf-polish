// Uso: swift hasfont.swift "Nombre de fuente"
// Dice si la fuente está instalada en macOS; si no, sugiere nombres parecidos.
import Foundation
import AppKit

guard CommandLine.arguments.count >= 2 else { print("Uso: hasfont.swift \"Fuente\""); exit(1) }
let wanted = CommandLine.arguments[1]
let families = NSFontManager.shared.availableFontFamilies
if families.contains(where: { $0.caseInsensitiveCompare(wanted) == .orderedSame }) {
    print("OK: \(wanted)")
} else {
    let key = wanted.lowercased().split(separator: " ").first.map(String.init) ?? wanted.lowercased()
    let similar = families.filter { $0.lowercased().contains(key) }.prefix(6)
    print("MISSING: \(wanted)" + (similar.isEmpty ? "" : " · parecidas: " + similar.joined(separator: ", ")))
    exit(2)
}
