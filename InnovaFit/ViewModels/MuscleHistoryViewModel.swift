import Foundation
import SwiftUI

class MuscleHistoryViewModel: ObservableObject {
    @Published var logs: [ExerciseLog] = []

    func fetchLogs() {
        // Fetch real de Firestore u origen real.
        ExerciseLogRepository.fetchLogsForCurrentUser { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let logs):
                    self?.logs = logs
                case .failure:
                    self?.logs = []
                }
            }
        }
    }

    // TOP 3 + Otros
    var muscleDistribution: [MuscleShare] {
        var counts: [String: Int] = [:]
        for log in logs {
            if let mainMuscle = log.muscleGroups.first {
                counts[mainMuscle, default: 0] += 1
            }
        }
        // Ordenar de mayor a menor
        let sorted = counts.sorted { $0.value > $1.value }
        var result: [MuscleShare] = []

        // Top 3
        for (idx, entry) in sorted.prefix(3).enumerated() {
            let color: Color
            switch idx {
            case 0: color = Color(hex: "#F9C534") // Amarillo
            case 1: color = Color(hex: "#569BF5") // Azul
            case 2: color = Color(hex: "#45D97B") // Verde
            default: color = Color(hex: "#E1E3E8") //gris claro
            }
            result.append(MuscleShare(muscle: entry.key, count: entry.value, color: color))
        }

        // Otros (si hay más de 3 grupos musculares)
        if sorted.count > 3 {
            let othersCount = sorted.dropFirst(3).map { $0.value }.reduce(0, +)
            if othersCount > 0 {
                result.append(MuscleShare(muscle: "Otros", count: othersCount, color: Color(hex: "#E1E1E1")))
            }
        }

        return result
    }

    var recentLogs: [ExerciseLog] {
        let sorted = logs.sorted { $0.timestamp > $1.timestamp }
        return Array(sorted.prefix(5))
    }
}

struct MuscleShare: Identifiable {
    var id: String { muscle }
    let muscle: String
    let count: Int
    let color: Color

    func percent(total: Int) -> Int {
        guard total > 0 else { return 0 }
        return Int(round(Double(count) / Double(total) * 100))
    }
    func percentString(total: Int) -> String {
        "\(percent(total: total))%"
    }
}

extension MuscleHistoryViewModel {
    var donutSegments: [DonutSegment] {
        let total = logs.count
        guard total > 0 else { return [] }
        return muscleDistribution.map { share in
            DonutSegment(percent: Double(share.count) / Double(total), color: share.color)
        }
    }
    
}
