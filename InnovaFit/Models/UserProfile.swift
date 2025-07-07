import Foundation

/// Perfil de usuario almacenado en Firestore
struct UserProfile: Codable, Identifiable {
    let id: String
    let name: String
    let phoneNumber: String
    let age: Int
    let gender: Gender
    /// Identificador del gimnasio al que pertenece el usuario
    let gymId: String
    /// Información básica del gimnasio (sin el id de documento)
    let gym: Gym
    var weight: Double
    var height: Double
}
