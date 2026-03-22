import Foundation
import FirebaseFirestore
import FirebaseAuth

class RoutineRepository {
    private static let db = Firestore.firestore()

    // MARK: - Get active routine for user

    static func getActiveRoutine(
        userId: String,
        completion: @escaping (Routine?) -> Void
    ) {
        db.collection("routines")
            .whereField("userId", isEqualTo: userId)
            .whereField("status", isEqualTo: "activa")
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error al obtener rutina activa: \(error.localizedDescription)")
                    completion(nil)
                    return
                }

                guard let doc = snapshot?.documents.first else {
                    print("⚠️ No se encontró rutina activa para userId: \(userId)")
                    completion(nil)
                    return
                }

                let routine = parseRoutine(from: doc)
                completion(routine)
            }
    }

    // MARK: - Start routine

    static func startRoutine(
        routineId: String,
        durationWeeks: Int,
        completion: @escaping (Bool) -> Void
    ) {
        let now = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: durationWeeks * 7, to: now) ?? now

        db.collection("routines").document(routineId).updateData([
            "startDate": Timestamp(date: now),
            "endDate": Timestamp(date: endDate)
        ]) { error in
            if let error = error {
                print("❌ Error al iniciar rutina: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ Rutina iniciada")
                completion(true)
            }
        }
    }

    // MARK: - Complete exercise

    static func completeExercise(
        routineId: String,
        dateKey: String,
        dayNumber: Int,
        exerciseIndex: Int,
        completion: @escaping (Bool) -> Void
    ) {
        db.collection("routines").document(routineId).updateData([
            "progress.\(dateKey).dayNumber": dayNumber,
            "progress.\(dateKey).completed": FieldValue.arrayUnion([exerciseIndex])
        ]) { error in
            if let error = error {
                print("❌ Error al completar ejercicio: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ Ejercicio completado: day=\(dayNumber), index=\(exerciseIndex), dateKey=\(dateKey)")
                completion(true)
            }
        }
    }

    // MARK: - Get machine with gym enrichment

    static func getMachineById(
        machineId: String,
        gymId: String,
        completion: @escaping (Machine?) -> Void
    ) {
        let group = DispatchGroup()
        var baseMachine: Machine?
        var locationFromGym: String?

        group.enter()
        db.collection("machines").document(machineId).getDocument { snapshot, error in
            defer { group.leave() }
            guard let doc = snapshot, error == nil else {
                print("❌ Error al cargar máquina \(machineId): \(error?.localizedDescription ?? "")")
                return
            }
            baseMachine = try? doc.data(as: Machine.self)
        }

        group.enter()
        db.collection("gym_machines")
            .whereField("gymId", isEqualTo: gymId)
            .whereField("machineId", isEqualTo: machineId)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                defer { group.leave() }
                if let doc = snapshot?.documents.first {
                    locationFromGym = doc["location"] as? String
                }
            }

        group.notify(queue: .main) {
            guard var machine = baseMachine else {
                completion(nil)
                return
            }
            machine.location = locationFromGym
            completion(machine)
        }
    }

    // MARK: - Save exercise log

    static func saveExerciseLog(
        machine: Machine,
        gymId: String,
        videoTitle: String,
        completion: @escaping (Bool) -> Void
    ) {
        guard let userId = Auth.auth().currentUser?.uid,
              let machineId = machine.id else {
            completion(false)
            return
        }

        let data: [String: Any] = [
            "userId": userId,
            "gymId": gymId,
            "machineId": machineId,
            "machineName": machine.name,
            "machineImageUrl": machine.imageUrl,
            "videoId": UUID().uuidString,
            "videoTitle": videoTitle,
            "muscleGroups": [] as [String],
            "mainMuscle": "",
            "timestamp": FieldValue.serverTimestamp()
        ]

        db.collection("exercise_logs").addDocument(data: data) { error in
            if let error = error {
                print("❌ Error al guardar exercise log: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    // MARK: - Manual Firestore parsing

    static func parseRoutine(from doc: QueryDocumentSnapshot) -> Routine? {
        let data = doc.data()

        let id = doc.documentID
        let name = data["name"] as? String ?? ""
        let objective = data["objective"] as? String ?? ""
        let notes = data["notes"] as? String ?? ""
        let userId = data["userId"] as? String ?? ""
        let gymId = data["gymId"] as? String ?? ""
        let status = data["status"] as? String ?? ""
        let durationWeeks = data["durationWeeks"] as? Int ?? 4

        let startDate = (data["startDate"] as? Timestamp)?.dateValue()
        let endDate = (data["endDate"] as? Timestamp)?.dateValue()

        let daysData = data["days"] as? [[String: Any]] ?? []
        let days: [RoutineDay] = daysData.enumerated().map { index, dayMap in
            let dayNumber = dayMap["dayNumber"] as? Int ?? (index + 1)
            let label = dayMap["label"] as? String ?? "Día \(dayNumber)"
            let isRest = dayMap["isRest"] as? Bool ?? false
            let exercisesData = dayMap["exercises"] as? [[String: Any]] ?? []
            let exercises: [RoutineExercise] = exercisesData.map { ex in
                RoutineExercise(
                    machineId: ex["machineId"] as? String ?? "",
                    machineName: ex["machineName"] as? String ?? "",
                    videoTitle: ex["videoTitle"] as? String ?? "",
                    sets: ex["sets"] as? Int ?? 3,
                    reps: ex["reps"] as? Int ?? 12,
                    weight: ex["weight"] as? Double ?? 0
                )
            }
            return RoutineDay(dayNumber: dayNumber, label: label, isRest: isRest, exercises: exercises)
        }

        let progressData = data["progress"] as? [String: [String: Any]] ?? [:]
        var progress: [String: DayProgress] = [:]
        for (key, value) in progressData {
            let dayNumber = value["dayNumber"] as? Int ?? 0
            let completed = value["completed"] as? [Int] ?? []
            progress[key] = DayProgress(dayNumber: dayNumber, completed: completed)
        }

        return Routine(
            id: id,
            name: name,
            objective: objective,
            notes: notes,
            userId: userId,
            gymId: gymId,
            startDate: startDate,
            endDate: endDate,
            durationWeeks: durationWeeks,
            status: status,
            days: days,
            progress: progress
        )
    }
}
