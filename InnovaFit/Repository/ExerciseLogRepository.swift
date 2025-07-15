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

                let data: [String: Any] = [
                    "userId": userId,
                    "videoId": video.id,
                    "videoTitle": video.title,
                    "machineId": machineId,
                    "machineName": machine.name,
                    "machineImageUrl": machine.imageUrl,
                    "muscleGroups": Array(video.musclesWorked.keys),
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
            completion(.success([]))
            return
        }
        
        var calendar = Calendar.current
        // Establecer lunes como primer día de la semana
        calendar.firstWeekday = 2
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        guard let startOfWeek = calendar.date(from: components) else {
            completion(.success([]))
            return
        }

        collection
            .whereField("userId", isEqualTo: userId)
            .whereField("timestamp", isGreaterThanOrEqualTo: Timestamp(date: startOfWeek))
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error { completion(.failure(error)); return }
                
                let logs = snapshot?.documents.compactMap {
                    try? $0.data(as: ExerciseLog.self)
                } ?? []
                
                completion(.success(logs))
            }
    }
}

