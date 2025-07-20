import Foundation
import FirebaseFirestore

class MachineRepository {
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
        print("📥 Loading Machine with id: \(machineId)")
        db.collection("machines").document(machineId).getDocument { snapshot, error in
            guard let doc = snapshot, error == nil else {
                print("❌ Error al cargar Machine: \(error?.localizedDescription ?? "desconocido")")
                completion(nil)
                return
            }

            do {
                // Aquí Firestore usa el modelo Machine para decodificar JSON automáticamente
                let machine = try doc.data(as: Machine.self)
                print("✅ Machine loaded: \(machine.name)")
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
        print("📥 Loading Gym with id: \(gymId)")
        db.collection("gyms").document(gymId).getDocument { snapshot, error in
            guard let doc = snapshot, error == nil else {
                print("❌ Error al cargar Gym: \(error?.localizedDescription ?? "desconocido")")
                completion(nil)
                return
            }

            do {
                let gym = try doc.data(as: Gym.self)
                print("✅ Gym loaded: \(gym.name)")
                completion(gym)
            } catch {
                print("❌ Error al parsear Gym: \(error)")
                completion(nil)
            }
        }
    }
    
    static func fetchMachinesByGym(forGymId gymId: String, completion: @escaping (Result<[Machine], Error>) -> Void) {
        let db = Firestore.firestore()
        print("📥 Iniciando consulta de gym_machines para gymId: \(gymId)")
        
        db.collection("gym_machines")
            .whereField("gymId", isEqualTo: gymId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error al consultar gym_machines: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("⚠️ No se encontraron vínculos gym_machines")
                    completion(.success([]))
                    return
                }

                let machineIds = documents.compactMap { $0["machineId"] as? String }
                print("✅ IDs de máquinas encontrados: \(machineIds)")

                guard !machineIds.isEmpty else {
                    print("⚠️ Lista de machineIds está vacía")
                    completion(.success([]))
                    return
                }

                db.collection("machines")
                    .whereField(FieldPath.documentID(), in: machineIds)
                    .getDocuments { machineSnapshot, error in
                        if let error = error {
                            print("❌ Error al consultar machines: \(error.localizedDescription)")
                            completion(.failure(error))
                            return
                        }

                        let machines = machineSnapshot?.documents.compactMap {
                            try? $0.data(as: Machine.self)
                        } ?? []

                        print("📦 Máquinas cargadas: \(machines.count)")
                        machines.forEach { print("🔹 \($0.name)") }

                        completion(.success(machines))
                    }
            }
    }

}

