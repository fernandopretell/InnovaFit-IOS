import Foundation
import FirebaseAuth
import FirebaseFirestore

class ExerciseLogRepository {
    static private let collection = Firestore.firestore().collection("exercise_logs")

    /// Registra un ejercicio para el usuario actual si no existe uno en la fecha actual.
    /// - Parameters:
    ///   - video: Video que se reprodujo.
    ///   - machine: Máquina asociada al video.
    ///   - completion: Callback con `true` si se registró un nuevo log.
    static func registerLogIfNeeded(
        video: Video,
        machine: Machine,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        guard let userId = Auth.auth().currentUser?.uid,
              let machineId = machine.id else {
            completion(.failure(NSError(
                domain: "ExerciseLogRepository",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Usuario o máquina inválidos"]
            )))
            return
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            completion(.failure(NSError(
                domain: "ExerciseLogRepository",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "No se pudo calcular fin de día"]
            )))
            return
        }

        collection
            .whereField("userId", isEqualTo: userId)
            .whereField("videoId", isEqualTo: video.id)
            .whereField("timestamp", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
            .whereField("timestamp", isLessThan: Timestamp(date: endOfDay))
            .getDocuments { snapshot, error in
                if let error { completion(.failure(error)); return }

                if let count = snapshot?.documents.count, count > 0 {
                    completion(.success(false))
                    return
                }

                let mainMuscle = video.musclesWorked.max { lhs, rhs in
                    lhs.value.weight < rhs.value.weight
                }?.key ?? ""

                let data: [String: Any] = [
                    "userId": userId,
                    "videoId": video.id,
                    "videoTitle": video.title,
                    "machineId": machineId,
                    "machineName": machine.name,
                    "machineImageUrl": machine.imageUrl,
                    "muscleGroups": Array(video.musclesWorked.keys),
                    "mainMuscle": mainMuscle,
                    "timestamp": FieldValue.serverTimestamp()
                ]

                collection.addDocument(data: data) { error in
                    if let error { completion(.failure(error)) }
                    else { completion(.success(true)) }
                }
            }
    }
    
    static func fetchLogsForCurrentUser(
        completion: @escaping (Result<[ExerciseLog], Error>) -> Void
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No hay usuario logueado")
            completion(.success([]))
            return
        }
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        calendar.firstWeekday = 2 // Lunes como primer día de la semana
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        guard let startOfWeek = calendar.date(from: components) else {
            print("No se pudo calcular el startOfWeek")
            completion(.success([]))
            return
        }

        print("UserID: \(userId)")
        print("startOfWeek: \(startOfWeek) (\(startOfWeek.formatted(date: .abbreviated, time: .omitted)))")
        
        collection
            .whereField("userId", isEqualTo: userId)
            .whereField("timestamp", isGreaterThanOrEqualTo: Timestamp(date: startOfWeek))
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error {
                    print("Error en getDocuments: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                let logs = snapshot?.documents.compactMap { doc in
                    do {
                        return try doc.data(as: ExerciseLog.self)
                    } catch {
                        print("Error decodificando doc ID: \(doc.documentID): \(error)")
                        return nil
                    }
                }

                print("Total documentos recibidos: \(snapshot?.documents.count ?? 0)")
                for doc in snapshot?.documents ?? [] {
                    if let ts = doc.get("timestamp") as? Timestamp {
                        let date = ts.dateValue()
                        print("Doc ID: \(doc.documentID) | Timestamp: \(date) (\(date.formatted(date: .abbreviated, time: .omitted)))")
                    }
                }
                print("Total logs decodificados: \(logs?.count ?? 0)")

                completion(.success(logs!))
            }
    }

}

