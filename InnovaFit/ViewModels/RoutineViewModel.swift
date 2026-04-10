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
    @Published var currentWeekNumber: Int = 1

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

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

        // Solo se puede completar el día actual
        guard selectedDayIndex == todayDayIndex else {
            completion(false)
            return
        }

        // Ya completado
        if todayProgress.contains(exerciseIndex) {
            completion(false)
            return
        }

        isCompletingExercise = true

        // Usar la fecha de hoy como dateKey (igual que Android getTodayDateKey())
        let dateKey = dateFormatter.string(from: Date())

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
                    // Actualizar estado local optimistamente
                    if !self.todayProgress.contains(exerciseIndex) {
                        self.todayProgress.append(exerciseIndex)
                    }
                    self.selectedDayProgress = self.todayProgress

                    // Actualizar progress map local y recalcular
                    var updatedProgress = routine.progress
                    let current = updatedProgress[dateKey]
                    let updatedCompleted = (current?.completed ?? []) + [exerciseIndex]
                    updatedProgress[dateKey] = DayProgress(dayNumber: dayNumber, completed: updatedCompleted)
                    let updatedRoutine = Routine(
                        id: routine.id,
                        name: routine.name,
                        objective: routine.objective,
                        notes: routine.notes,
                        userId: routine.userId,
                        gymId: routine.gymId,
                        startDate: routine.startDate,
                        endDate: routine.endDate,
                        durationWeeks: routine.durationWeeks,
                        status: routine.status,
                        days: routine.days,
                        progress: updatedProgress
                    )
                    self.routine = updatedRoutine
                    self.recalculateProgress()

                    // Guardar log de ejercicio
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
            currentWeekNumber = 1
            weeklyStats = WeeklyStats(weeklyProgress: [], currentWeekIndex: 0, streak: 0, windowStart: 0)
            return
        }

        let daysSince = calendarDaysSince(startDate)
        let totalDays = routine.days.count
        guard totalDays > 0 else { return }

        todayDayIndex = daysSince % totalDays
        selectedDayIndex = todayDayIndex
        currentWeekNumber = (daysSince / 7) + 1

        todayProgress = progressForDay(todayDayIndex, routine: routine)
        selectedDayProgress = todayProgress

        recalculateProgress()
    }

    /// Lee el progreso para un dayIndex en el ciclo actual.
    /// Calcula el dayOffset real basándose en el ciclo actual (semana).
    private func progressForDay(_ dayIndex: Int, routine: Routine) -> [Int] {
        guard let startDate = routine.startDate else { return [] }
        let daysSince = calendarDaysSince(startDate)
        let totalDays = routine.days.count
        guard totalDays > 0 else { return [] }

        // Calcular el offset real para este dayIndex en el ciclo actual
        let currentCycle = daysSince / totalDays
        let dayOffset = currentCycle * totalDays + dayIndex
        let dateKey = dateKeyForOffset(startDate, dayOffset: dayOffset)
        return routine.progress[dateKey]?.completed ?? []
    }

    private func recalculateProgress() {
        guard let routine = routine, let startDate = routine.startDate else { return }

        let totalDays = routine.days.count
        guard totalDays > 0 else { return }

        let daysSince = calendarDaysSince(startDate)

        // ── Global progress: iterar sobre TODAS las semanas ──
        var totalExercises = 0
        var completedExercises = 0

        let totalWeeks = max(1, routine.durationWeeks)
        for week in 0..<totalWeeks {
            let weekStart = week * 7
            let weekEnd = weekStart + 6
            let (expected, completed) = calculateProgressForRange(
                routine: routine,
                startDate: startDate,
                rangeStart: weekStart,
                rangeEnd: weekEnd,
                daysSinceStart: daysSince
            )
            totalExercises += expected
            completedExercises += completed
        }

        globalProgress = totalExercises > 0
            ? min(1, Float(completedExercises) / Float(totalExercises))
            : 0

        // ── Weekly stats: sliding window de 4 semanas ──
        let currentWeek = daysSince / 7  // 0-based

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
                weekProgressArray.append(-1) // semana futura
                continue
            }
            let weekEndDay = weekStartDay + 6
            let (expected, completed) = calculateProgressForRange(
                routine: routine,
                startDate: startDate,
                rangeStart: weekStartDay,
                rangeEnd: weekEndDay,
                daysSinceStart: daysSince
            )
            weekProgressArray.append(expected > 0 ? min(1, Float(completed) / Float(expected)) : 0)
        }

        // Streak: semanas consecutivas al 80%+
        var streak = 0
        let currentWeekInWindow = currentWeek - windowStart
        // Solo contar semanas completas para el streak
        let currentWeekLastDay = (currentWeek + 1) * 7 - 1
        let streakStart = daysSince >= currentWeekLastDay ? currentWeekInWindow : currentWeekInWindow - 1

        for i in stride(from: streakStart, through: 0, by: -1) {
            if i >= 0 && i < weekProgressArray.count && weekProgressArray[i] >= 0.8 {
                streak += 1
            } else {
                break
            }
        }

        weeklyStats = WeeklyStats(
            weeklyProgress: weekProgressArray,
            currentWeekIndex: max(0, min(currentWeekInWindow, weekProgressArray.count - 1)),
            streak: streak,
            windowStart: windowStart
        )
    }

    /// Calcula ejercicios esperados vs completados para un rango de dayOffsets.
    /// Replica la lógica de Android calculateProgressForRange().
    private func calculateProgressForRange(
        routine: Routine,
        startDate: Date,
        rangeStart: Int,
        rangeEnd: Int,
        daysSinceStart: Int
    ) -> (expected: Int, completed: Int) {
        let totalDays = routine.days.count
        guard totalDays > 0 else { return (0, 0) }

        // Paso 1: recoger dayNumbers que ya tienen progreso en este rango
        var rangeCompletedDayNumbers = Set<Int>()
        for dayOffset in rangeStart...rangeEnd {
            if dayOffset > daysSinceStart { break }
            let dateKey = dateKeyForOffset(startDate, dayOffset: dayOffset)
            if let dp = routine.progress[dateKey] {
                rangeCompletedDayNumbers.insert(dp.dayNumber)
            }
        }

        // Paso 2: calcular expected y completed
        var expected = 0
        var completed = 0
        for dayOffset in rangeStart...rangeEnd {
            if dayOffset > daysSinceStart { break }
            let dayIndex = dayOffset % totalDays
            let day = routine.days[dayIndex]
            let dateKey = dateKeyForOffset(startDate, dayOffset: dayOffset)
            let dayProgress = routine.progress[dateKey]

            if let dp = dayProgress {
                // Existe progreso para esta fecha
                if let actualDay = routine.days.first(where: { $0.dayNumber == dp.dayNumber }),
                   !actualDay.isRest {
                    expected += actualDay.exercises.count
                    completed += dp.completed.count
                }
            } else if !day.isRest && !rangeCompletedDayNumbers.contains(day.dayNumber) {
                // No hay progreso, no es descanso, y este dayNumber no fue completado
                // en otra fecha del mismo rango => cuenta como esperado
                expected += day.exercises.count
            }
        }
        return (expected, completed)
    }

    // MARK: - Date utilities

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
        return dateFormatter.string(from: date)
    }
}
