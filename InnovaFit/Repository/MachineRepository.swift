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
                print("⚠️ snapshot de Machine es nil")
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
                print("⚠️ snapshot de Gym es nil")
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

                // Extraer machineId y location de cada documento gym_machines
                var machineIds: [String] = []
                var locationById: [String: String] = [:]
                for doc in documents {
                    guard let machineId = doc["machineId"] as? String else { continue }
                    machineIds.append(machineId)
                    if let location = doc["location"] as? String, !location.isEmpty {
                        locationById[machineId] = location
                    }
                }
                print("✅ IDs de máquinas encontrados: \(machineIds)")

                guard !machineIds.isEmpty else {
                    print("⚠️ Lista de machineIds está vacía")
                    completion(.success([]))
                    return
                }

                // Firestore limita el operador `in` a 10 valores.
                let batchLimit = 10
                let uniqueIds = Array(Set(machineIds))
                let chunks: [[String]] = stride(from: 0, to: uniqueIds.count, by: batchLimit).map {
                    Array(uniqueIds[$0 ..< min($0 + batchLimit, uniqueIds.count)])
                }

                print("🔧 Consultando machines en \(chunks.count) lote(s)")

                let machinesCollection = db.collection("machines")
                let group = DispatchGroup()
                var firstError: Error?
                var fetchedById: [String: Machine] = [:]

                for chunk in chunks {
                    group.enter()
                    machinesCollection
                        .whereField(FieldPath.documentID(), in: chunk)
                        .getDocuments { machineSnapshot, error in
                            if let error = error {
                                if firstError == nil { firstError = error }
                                print("❌ Error al consultar machines (lote): \(error.localizedDescription)")
                                group.leave()
                                return
                            }

                            machineSnapshot?.documents.forEach { doc in
                                do {
                                    var machine = try doc.data(as: Machine.self)
                                    // Asignar location desde gym_machines
                                    if let loc = locationById[doc.documentID] {
                                        machine.location = loc
                                    }
                                    fetchedById[doc.documentID] = machine
                                } catch {
                                    print("❌ Error decodificando machine \(doc.documentID): \(error)")
                                    print("📄 Data: \(doc.data())")
                                }
                            }
                            group.leave()
                        }
                }

                group.notify(queue: .main) {
                    if let error = firstError {
                        completion(.failure(error))
                        return
                    }

                    // Preservar el orden según machineIds, sin duplicados
                    var seen = Set<String>()
                    let orderedMachines: [Machine] = machineIds.compactMap { id in
                        guard !seen.contains(id), let m = fetchedById[id] else { return nil }
                        seen.insert(id)
                        return m
                    }

                    print("📦 Máquinas cargadas: \(orderedMachines.count)")
                    orderedMachines.forEach { print("🔹 \($0.name) - 📍 \($0.location ?? "sin ubicación")") }

                    completion(.success(orderedMachines))
                }
            }
    }

}
