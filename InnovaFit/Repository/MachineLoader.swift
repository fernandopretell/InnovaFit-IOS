import Foundation
import FirebaseFirestore

class MachineLoader {
    /// Consulta Firestore para obtener `gymId` y `machineId` a partir del `tag`.
    static func resolveTag(
        tag: String,
        completion: @escaping (_ gymId: String?, _ machineId: String?) -> Void
    ) {
        let db = Firestore.firestore()
        let docRef = db.collection("tags").document(tag)

        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                print("❌ Error al obtener datos de tag: \(error?.localizedDescription ?? "desconocido")")
                completion(nil, nil)
                return
            }

            let gymId = data["gymId"] as? String
            let machineId = data["machineId"] as? String

            print("✅ Obtenido desde tag=\(tag): gymId=\(gymId ?? "nil"), machineId=\(machineId ?? "nil")")

            completion(gymId, machineId)
        }
    }

    /// Carga un `Machine` desde Firestore dado su `machineId`.
    static func loadMachine(machineId: String, completion: @escaping (Machine?) -> Void) {
        let db = Firestore.firestore()
        db.collection("machines").document(machineId).getDocument { snapshot, error in
            guard let doc = snapshot, error == nil else {
                print("❌ Error al cargar Machine: \(error?.localizedDescription ?? "desconocido")")
                completion(nil)
                return
            }

            do {
                // Aquí Firestore usa el modelo Machine para decodificar JSON automáticamente
                let machine = try doc.data(as: Machine.self)
                completion(machine)
            } catch {
                print("❌ Error al parsear Machine: \(error)")
                completion(nil)
            }
        }
    }


    /// Carga un `Gym` desde Firestore dado su `gymId`.
    static func loadGym(gymId: String, completion: @escaping (Gym?) -> Void) {
        let db = Firestore.firestore()
        db.collection("gyms").document(gymId).getDocument { snapshot, error in
            guard let doc = snapshot, error == nil else {
                print("❌ Error al cargar Gym: \(error?.localizedDescription ?? "desconocido")")
                completion(nil)
                return
            }

            do {
                let gym = try doc.data(as: Gym.self)
                completion(gym)
            } catch {
                print("❌ Error al parsear Gym: \(error)")
                completion(nil)
            }
        }
    }
}

