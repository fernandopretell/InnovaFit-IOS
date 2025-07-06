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

extension Color {
    static let innovaBackground = Color(hex: "#0F0F0F") // negro suave
    static let innovaYellow     = Color(hex: "#FFD600") // amarillo marca
    
    static let textTitle        = Color(hex: "#111111")
    static let textSubtitle     = Color(hex: "#3C3C3C")
    static let textBody         = Color(hex: "#5A5A5A")
    static let textPlaceholder  = Color(hex: "#9B9B9B")
    
    static let backgroundFields  = Color(hex: "#F6F4EC")
}


