import Foundation

struct Routine: Identifiable {
    let id: String
    let name: String
    let objective: String
    let notes: String
    let userId: String
    let gymId: String
    let startDate: Date?
    let endDate: Date?
    let durationWeeks: Int
    let status: String
    let days: [RoutineDay]
    let progress: [String: DayProgress]
}

struct RoutineDay {
    let dayNumber: Int
    let label: String
    let isRest: Bool
    let exercises: [RoutineExercise]
}

struct RoutineExercise {
    let machineId: String
    let machineName: String
    let videoTitle: String
    let sets: Int
    let reps: Int
    let weight: Double
}

struct DayProgress {
    let dayNumber: Int
    let completed: [Int]
}

struct WeeklyStats {
    /// Per-week progress: 0..1 for past/current weeks, -1 for future weeks
    let weeklyProgress: [Float]
    /// Index into weeklyProgress that represents the current week
    let currentWeekIndex: Int
    /// Consecutive weeks at >=80% completion
    let streak: Int
    /// Offset applied to display labels (S1 = windowStart+1)
    let windowStart: Int
}
