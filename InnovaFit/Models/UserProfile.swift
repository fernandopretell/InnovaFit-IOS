import Foundation

/// Perfil de usuario almacenado en Firestore
struct UserProfile: Codable, Identifiable {
    let id: String
    let name: String
    let phoneNumber: String
    let age: Int
    let gender: String
    /// Identificador real del gimnasio asociado
    let gymId: String
    /// Datos del gimnasio. Al decodificar desde Firestore el campo `id` puede
    /// no contener el valor correcto, por lo que se usa `gymId` como fuente de
    /// verdad.
    var gym: Gym?
    var weight: Double
    var height: Double
}
