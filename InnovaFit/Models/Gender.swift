import Foundation

/// Representa el género de un usuario
enum Gender: String, Codable, CaseIterable, Identifiable {
    case masculino
    case femenino

    var id: String { rawValue }
}
