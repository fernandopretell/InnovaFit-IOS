import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Maneja operaciones de lectura y escritura de perfiles de usuario en Firestore
class UserRepository {
    private let db = Firestore.firestore()
    private let usersCollection = "users"
    private let gymsCollection = "gyms"

    /// Guarda un `UserProfile` en la colección "users" usando el UID de FirebaseAuth
    func saveUserProfile(_ user: UserProfile, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try db.collection(usersCollection).document(user.id).setData(from: user) { error in
                if let error { completion(.failure(error)) } else { completion(.success(())) }
            }
        } catch {
            completion(.failure(error))
        }
    }

    /// Obtiene un `UserProfile` por su UID
    func fetchUserProfile(uid: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        db.collection(usersCollection).document(uid).getDocument { [weak self] snapshot, error in
            guard let self else { return }
            if let error { completion(.failure(error)); return }
            guard let doc = snapshot, doc.exists else {
                completion(.failure(NSError(domain: "UserRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Perfil no encontrado"])))
                return
            }
            do {
                var profile = try doc.data(as: UserProfile.self)
                // Fetch gym from gyms collection to get all fields (e.g. isQrEnabled)
                self.db.collection(self.gymsCollection).document(profile.gymId).getDocument { gymSnapshot, gymError in
                    if let gymDoc = gymSnapshot, gymDoc.exists,
                       var gym = try? gymDoc.data(as: Gym.self) {
                        gym.id = profile.gymId
                        profile.gym = gym
                    } else if var gym = profile.gym {
                        gym.id = profile.gymId
                        profile.gym = gym
                    }
                    completion(.success(profile))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Obtiene la lista de gimnasios disponibles
    func fetchGyms(completion: @escaping (Result<[Gym], Error>) -> Void) {
        db.collection(gymsCollection).getDocuments { snapshot, error in
            if let error { completion(.failure(error)); return }
            let gyms = snapshot?.documents.compactMap { try? $0.data(as: Gym.self) } ?? []
            completion(.success(gyms))
        }
    }
}
