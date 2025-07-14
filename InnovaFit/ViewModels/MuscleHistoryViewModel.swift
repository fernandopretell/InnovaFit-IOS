import Foundation
import SwiftUI

class MuscleHistoryViewModel: ObservableObject {
    @Published var logs: [ExerciseLog] = []

    func fetchLogs() {
        ExerciseLogRepository.fetchLogsForCurrentUser { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let logs):
                    self?.logs = logs
                case .failure(let error):
                    print("Error fetching logs: \(error)")
                    self?.logs = []
                }
            }
        }
    }

    var muscleDistribution: [MuscleShare] {
        var counts: [String: Int] = [:]
        for log in logs {
            for group in log.muscleGroups {
                counts[group, default: 0] += 1
            }
        }
        return counts.map { key, value in
            MuscleShare(muscle: key, count: value)
        }
    }

    var recentLogs: [ExerciseLog] {
        Array(logs.sorted { $0.timestamp > $1.timestamp }.prefix(5))
    }
}

struct MuscleShare: Identifiable {
    var id: String { muscle }
    let muscle: String
    let count: Int

    var color: Color {
        switch muscle.lowercased() {
        case "cuádriceps", "cuadriceps":
            return .yellow
        case "glúteos", "gluteos":
            return .blue
        case "espalda":
            return .green
        default:
            return .gray
        }
    }
}
