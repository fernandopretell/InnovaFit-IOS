import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Maneja operaciones de lectura y escritura de perfiles de usuario en Firestore
class UserRepository {
    private let db = Firestore.firestore()

    /// Guarda un `UserProfile` en la colección "users" usando el UID de FirebaseAuth
    func saveUserProfile(_ user: UserProfile, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try db.collection("users").document(user.id).setData(from: user) { error in
                if let error { completion(.failure(error)) } else { completion(.success(())) }
            }
        } catch {
            completion(.failure(error))
        }
    }

    /// Obtiene un `UserProfile` por su UID
    func fetchUserProfile(uid: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error { completion(.failure(error)); return }
            guard let doc = snapshot, doc.exists else {
                completion(.failure(NSError(domain: "UserRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Perfil no encontrado"])))
                return
            }
            do {
                let profile = try doc.data(as: UserProfile.self)
                completion(.success(profile))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Obtiene la lista de gimnasios disponibles
    func fetchGyms(completion: @escaping (Result<[Gym], Error>) -> Void) {
        db.collection("gyms").getDocuments { snapshot, error in
            if let error { completion(.failure(error)); return }
            let gyms = snapshot?.documents.compactMap { try? $0.data(as: Gym.self) } ?? []
            completion(.success(gyms))
        }
    }
}
