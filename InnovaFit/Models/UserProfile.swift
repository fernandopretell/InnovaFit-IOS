import Foundation

/// Perfil de usuario almacenado en Firestore
struct UserProfile: Codable, Identifiable {
    let id: String
    let name: String
    let phoneNumber: String
    let age: Int
    let gender: Gender
    let gym: Gym
}
