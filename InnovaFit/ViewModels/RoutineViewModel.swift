import Foundation
import Combine

class RoutineViewModel: ObservableObject {
    @Published var routine: Routine?
    @Published var isLoading = false
    @Published var isRoutineStarted = false
    @Published var isStarting = false
    @Published var isCompletingExercise = false
    @Published var isLoadingMachine = false

    @Published var todayDayIndex = 0
    @Published var selectedDayIndex = 0

    @Published var todayProgress: [Int] = []
    @Published var selectedDayProgress: [Int] = []

    @Published var selectedMachine: Machine?
    @Published var dayMachines: [String: Machine] = [:]

    @Published var globalProgress: Float = 0
    @Published var weeklyStats = WeeklyStats(weeklyProgress: [], currentWeekIndex: 0, streak: 0, windowStart: 0)

    // MARK: - Load routine

    func loadRoutine(userId: String) {
        guard !isLoading, routine == nil else { return }
        isLoading = true

        RoutineRepository.getActiveRoutine(userId: userId) { [weak self] routine in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                guard let routine = routine else { return }
                self.routine = routine
                self.isRoutineStarted = routine.startDate != nil
                self.recalculate(for: routine)
            }
        }
    }

    // MARK: - Select day

    func selectDay(index: Int) {
        selectedDayIndex = index
        guard let routine = routine else { return }
        selectedDayProgress = progressForDay(index, routine: routine)
    }

    // MARK: - Start routine

    func startRoutine() {
        guard let routine = routine else { return }
        isStarting = true

        RoutineRepository.startRoutine(routineId: routine.id, durationWeeks: routine.durationWeeks) { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isStarting = false
                if success {
                    self.reloadRoutine(userId: routine.userId)
                }
            }
        }
    }

    // MARK: - Load machine for exercise

    func loadMachineForExercise(machineId: String, gymId: String) {
        if let cached = dayMachines[machineId] {
            selectedMachine = cached
            return
        }
        isLoadingMachine = true
        RoutineRepository.getMachineById(machineId: machineId, gymId: gymId) { [weak self] machine in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoadingMachine = false
                if let machine = machine {
                    self.dayMachines[machineId] = machine
                    self.selectedMachine = machine
                }
            }
        }
    }

    // MARK: - Complete exercise

    func completeExercise(
        dayNumber: Int,
        exerciseIndex: Int,
        gymId: String,
        exercise: RoutineExercise,
        completion: @escaping (Bool) -> Void
    ) {
        guard let routine = routine, let startDate = routine.startDate else {
            completion(false)
            return
        }

        isCompletingExercise = true

        let dayOffset = selectedDayIndex
        let dateKey = dateKeyForOffset(startDate, dayOffset: dayOffset)

        RoutineRepository.completeExercise(
            routineId: routine.id,
            dateKey: dateKey,
            dayNumber: dayNumber,
            exerciseIndex: exerciseIndex
        ) { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isCompletingExercise = false

                if success {
                    // Update local state
                    if !self.selectedDayProgress.contains(exerciseIndex) {
                        self.selectedDayProgress.append(exerciseIndex)
                    }
                    if self.selectedDayIndex == self.todayDayIndex, !self.todayProgress.contains(exerciseIndex) {
                        self.todayProgress.append(exerciseIndex)
                    }
                    self.recalculateProgress()

                    // Save exercise log
                    if let machine = self.dayMachines[exercise.machineId] {
                        RoutineRepository.saveExerciseLog(
                            machine: machine,
                            gymId: gymId,
                            videoTitle: exercise.videoTitle
                        ) { _ in }
                    }
                }
                completion(success)
            }
        }
    }

    // MARK: - Private helpers

    private func reloadRoutine(userId: String) {
        routine = nil
        isLoading = false
        loadRoutine(userId: userId)
    }

    private func recalculate(for routine: Routine) {
        guard let startDate = routine.startDate else {
            todayDayIndex = 0
            selectedDayIndex = 0
            todayProgress = []
            selectedDayProgress = []
            globalProgress = 0
            weeklyStats = WeeklyStats(weeklyProgress: [], currentWeekIndex: 0, streak: 0, windowStart: 0)
            return
        }

        let daysSince = calendarDaysSince(startDate)
        let totalDays = routine.days.count
        todayDayIndex = totalDays > 0 ? daysSince % totalDays : 0
        selectedDayIndex = todayDayIndex

        todayProgress = progressForDay(todayDayIndex, routine: routine)
        selectedDayProgress = todayProgress

        recalculateProgress()
    }

    private func recalculateProgress() {
        guard let routine = routine, let startDate = routine.startDate else { return }

        let totalDays = routine.days.count
        guard totalDays > 0 else { return }

        let daysSince = calendarDaysSince(startDate)

        // Global progress: completed exercises / total exercises across all days
        var totalExercises = 0
        var completedExercises = 0

        for dayIndex in 0..<totalDays {
            let day = routine.days[dayIndex]
            if day.isRest { continue }
            totalExercises += day.exercises.count

            let dateKey = dateKeyForOffset(startDate, dayOffset: dayIndex)
            let prog = routine.progress[dateKey]
            completedExercises += prog?.completed.count ?? 0
        }

        globalProgress = totalExercises > 0 ? Float(completedExercises) / Float(totalExercises) : 0

        // Weekly stats — sliding window of up to 4 weeks (matches Android)
        let totalWeeks = routine.durationWeeks
        let currentWeek = daysSince / 7

        let windowStart: Int
        if totalWeeks <= 4 {
            windowStart = 0
        } else if currentWeek <= 1 {
            windowStart = 0
        } else if currentWeek >= totalWeeks - 2 {
            windowStart = max(0, totalWeeks - 4)
        } else {
            windowStart = currentWeek - 1
        }
        let windowEnd = min(windowStart + 4, totalWeeks)

        var weekProgressArray: [Float] = []
        for week in windowStart..<windowEnd {
            let weekStartDay = week * 7
            if weekStartDay > daysSince {
                weekProgressArray.append(-1) // future week
                continue
            }
            let weekEndDay = weekStartDay + 6
            var expected = 0
            var completed = 0
            for dayOffset in weekStartDay...weekEndDay {
                let wrappedIndex = dayOffset % totalDays
                let day = routine.days[wrappedIndex]
                if day.isRest { continue }
                if dayOffset > daysSince { continue }
                expected += day.exercises.count
                let dateKey = dateKeyForOffset(startDate, dayOffset: dayOffset)
                completed += routine.progress[dateKey]?.completed.count ?? 0
            }
            weekProgressArray.append(expected > 0 ? min(1, Float(completed) / Float(expected)) : 0)
        }

        // Streak: consecutive weeks at >=80%
        var streak = 0
        let startWeek = min(currentWeek, windowEnd - 1)
        for week in stride(from: startWeek, through: 0, by: -1) {
            let ws = week * 7
            let we = ws + 6
            var exp = 0; var comp = 0
            for d in ws...we {
                let wi = d % totalDays
                let day = routine.days[wi]
                if day.isRest || d > daysSince { continue }
                exp += day.exercises.count
                let dk = dateKeyForOffset(startDate, dayOffset: d)
                comp += routine.progress[dk]?.completed.count ?? 0
            }
            let pct = exp > 0 ? Float(comp) / Float(exp) : 0
            if pct >= 0.8 { streak += 1 } else { break }
        }

        let currentWeekInWindow = currentWeek - windowStart
        weeklyStats = WeeklyStats(
            weeklyProgress: weekProgressArray,
            currentWeekIndex: currentWeekInWindow,
            streak: streak,
            windowStart: windowStart
        )
    }

    private func progressForDay(_ dayIndex: Int, routine: Routine) -> [Int] {
        guard let startDate = routine.startDate else { return [] }
        let dateKey = dateKeyForOffset(startDate, dayOffset: dayIndex)
        return routine.progress[dateKey]?.completed ?? []
    }

    func calendarDaysSince(_ startDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: startDate),
            to: calendar.startOfDay(for: Date())
        )
        return max(0, components.day ?? 0)
    }

    func dateKeyForOffset(_ startDate: Date, dayOffset: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: startDate) ?? startDate
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
