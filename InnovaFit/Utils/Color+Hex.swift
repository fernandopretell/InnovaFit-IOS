import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
                          .trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        let scanner = Scanner(string: hex)
        guard scanner.scanHexInt64(&int), hex.count == 6 else {
            // Color fallback si el hex no es válido (gris claro)
            self = Color.gray.opacity(0.3)
            return
        }

        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0

        self = Color(red: r, green: g, blue: b)
    }
}


