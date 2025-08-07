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

    // TOP 4 + Otros
    var muscleDistribution: [MuscleShare] {
        var counts: [String: Int] = [:]
        for log in logs {
            counts[log.muscleGroup, default: 0] += 1
        }
        // Ordenar de mayor a menor y de forma estable cuando hay empates
        let sorted = counts.sorted { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key < rhs.key
            } else {
                return lhs.value > rhs.value
            }
        }
        var result: [MuscleShare] = []

        // Top 4
        for (idx, entry) in sorted.prefix(4).enumerated() {
            let color: Color
            switch idx {
            case 0: color = Color(hex: "#F9C534") // Amarillo
            case 1: color = Color(hex: "#569BF5") // Azul
            case 2: color = Color(hex: "#45D97B") // Verde
            case 3: color = Color(hex: "#F66768") // Rojo (puedes cambiar el HEX si prefieres otro tono)
            default: color = Color(hex: "#E1E3E8") // Gris claro
            }
            result.append(MuscleShare(muscle: entry.key, count: entry.value, color: color))
        }

        // Otros (si hay más de 4 grupos musculares)
        if sorted.count > 4 {
            let othersCount = sorted.dropFirst(4).map { $0.value }.reduce(0, +)
            if othersCount > 0 {
                result.append(MuscleShare(muscle: "Otros", count: othersCount, color: Color(hex: "#E1E3E8")))
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

    func color(for muscle: String) -> Color {
        muscleDistribution.first(where: { $0.muscle == muscle })?.color ?? Color(hex: "#E1E3E8")
    }

}
