import SwiftUI

struct RoutineView: View {
    @ObservedObject var routineVM: RoutineViewModel
    let gymId: String
    let userId: String
    let gymColor: Color
    var onBack: (() -> Void)? = nil

    @State private var selectedExercise: (exercise: RoutineExercise, dayIndex: Int, exerciseIndex: Int)?
    @State private var showExerciseSheet = false

    var body: some View {
        Group {
            if routineVM.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(hex: "#FBFCF8").ignoresSafeArea())
            } else if let routine = routineVM.routine {
                if !routineVM.isRoutineStarted {
                    StartRoutineScreen(
                        routine: routine,
                        isStarting: routineVM.isStarting,
                        onBack: { onBack?() },
                        onStart: { routineVM.startRoutine() }
                    )
                } else {
                    ActiveRoutineScreen(
                        routine: routine,
                        routineVM: routineVM,
                        gymId: gymId,
                        gymColor: gymColor,
                        onBack: { onBack?() },
                        onExerciseTap: { exercise, dayIndex, exerciseIndex in
                            selectedExercise = (exercise, dayIndex, exerciseIndex)
                            routineVM.loadMachineForExercise(machineId: exercise.machineId, gymId: gymId)
                            showExerciseSheet = true
                        }
                    )
                }
            } else {
                Text("No hay rutina activa")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showExerciseSheet) {
            if let sel = selectedExercise {
                ExerciseDetailSheet(
                    exercise: sel.exercise,
                    dayIndex: sel.dayIndex,
                    exerciseIndex: sel.exerciseIndex,
                    routineVM: routineVM,
                    gymId: gymId,
                    gymColor: gymColor,
                    isToday: sel.dayIndex == routineVM.todayDayIndex
                )
                .presentationDetents([.large])
            }
        }
    }
}

// MARK: - Start Routine Screen

private struct StartRoutineScreen: View {
    let routine: Routine
    let isStarting: Bool
    let onBack: () -> Void
    let onStart: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(hex: "#FBFCF8").ignoresSafeArea()

            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(10)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.08), radius: 4)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Spacer()

                VStack(spacing: 24) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 60))
                        .foregroundColor(.black.opacity(0.8))

                    VStack(spacing: 8) {
                        Text(routine.name)
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)

                        Text(routine.objective)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)

                        Text("\(routine.durationWeeks) semanas · \(routine.days.count) días")
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    .padding(.horizontal, 32)

                    Button(action: onStart) {
                        HStack {
                            if isStarting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .frame(width: 20, height: 20)
                            } else {
                                Text("Iniciar Rutina")
                                    .font(.headline.bold())
                                    .foregroundColor(.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .cornerRadius(16)
                    }
                    .disabled(isStarting)
                    .padding(.horizontal, 32)
                }

                Spacer()
            }
        }
    }
}

// MARK: - Active Routine Screen

private struct ActiveRoutineScreen: View {
    let routine: Routine
    @ObservedObject var routineVM: RoutineViewModel
    let gymId: String
    let gymColor: Color
    let onBack: () -> Void
    let onExerciseTap: (RoutineExercise, Int, Int) -> Void

    @State private var scrollProxy: ScrollViewProxy? = nil

    private var trainingDays: Int { routine.days.filter { !$0.isRest }.count }
    private var restDays: Int { routine.days.filter { $0.isRest }.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    Spacer()
                    Text("RUTINA ACTUAL")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(.black)
                        .tracking(1.5)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)

                // Header card with circular progress
                HeaderCard(
                    routine: routine,
                    globalProgress: routineVM.globalProgress,
                    trainingDays: trainingDays,
                    restDays: restDays,
                    weeklyStats: routineVM.weeklyStats
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)

                // Day selector
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(routine.days.enumerated()), id: \.offset) { index, day in
                                DayChip(
                                    day: day,
                                    dayIndex: index,
                                    isToday: index == routineVM.todayDayIndex,
                                    isSelected: index == routineVM.selectedDayIndex,
                                    dateLabel: dateLabelForDay(index),
                                    progress: routineVM.selectedDayIndex == index ? routineVM.selectedDayProgress : []
                                ) {
                                    routineVM.selectDay(index: index)
                                }
                                .id(index)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                proxy.scrollTo(routineVM.todayDayIndex, anchor: .center)
                            }
                        }
                    }
                }
                .padding(.bottom, 16)

                // Day content
                let selectedDay = routine.days[safe: routineVM.selectedDayIndex]
                if let day = selectedDay {
                    if day.isRest {
                        RestDayView()
                            .padding(.top, 32)
                    } else {
                        // Day label + completion count
                        HStack(alignment: .firstTextBaseline) {
                            Text(day.label.isEmpty ? "Entrenamiento" : day.label)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)

                            Spacer()

                            let completed = routineVM.selectedDayProgress.count
                            let total = day.exercises.count
                            Text("\(completed)/\(total) completados")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "#B8960C"))
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)

                        VStack(spacing: 24) {
                            ForEach(Array(day.exercises.enumerated()), id: \.offset) { exIndex, exercise in
                                let isCompleted = routineVM.selectedDayProgress.contains(exIndex)
                                let isPast = routineVM.selectedDayIndex < routineVM.todayDayIndex && !isCompleted
                                ExerciseCard(
                                    exercise: exercise,
                                    machine: routineVM.dayMachines[exercise.machineId],
                                    isCompleted: isCompleted,
                                    isMissed: isPast
                                ) {
                                    onExerciseTap(exercise, routineVM.selectedDayIndex, exIndex)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .background(Color(hex: "#FBFCF8").ignoresSafeArea())
        .task(id: routineVM.selectedDayIndex) {
            guard let day = routine.days[safe: routineVM.selectedDayIndex], !day.isRest else { return }
            for exercise in day.exercises {
                routineVM.loadMachineForExercise(machineId: exercise.machineId, gymId: gymId)
            }
        }
    }

    private func dateLabelForDay(_ index: Int) -> String {
        guard let startDate = routine.startDate else { return "" }
        guard let date = Calendar.current.date(byAdding: .day, value: index, to: startDate) else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}

// MARK: - Header Card

private struct HeaderCard: View {
    let routine: Routine
    let globalProgress: Float
    let trainingDays: Int
    let restDays: Int
    let weeklyStats: WeeklyStats

    private let gold = Color(hex: "#B8960C")

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(routine.objective.uppercased())
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(gold)
                        .tracking(1.2)

                    Text(routine.name)
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.black)

                    if !routine.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down.right")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Tu entrenador")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundColor(gold)

                            Text(routine.notes)
                                .font(.system(size: 13).italic())
                                .foregroundColor(Color(hex: "#171712").opacity(0.65))
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 4)
                    }
                }

                Spacer(minLength: 8)

                CircularProgressView(progress: globalProgress, size: 72)
            }

            Divider()
                .opacity(0.5)

            HStack {
                Label("Semana \(weeklyStats.currentWeekIndex + 1) de \(routine.durationWeeks)", systemImage: "calendar")
                Spacer()
                Text("\(trainingDays) entreno · \(restDays) descanso")
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Color(hex: "#171712").opacity(0.7))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Circular Progress

struct CircularProgressView: View {
    let progress: Float
    let size: CGFloat

    private let accent = Color(hex: "#FDD835")

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.12), lineWidth: 6)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: size, height: size)
                .animation(.easeOut(duration: 0.8), value: progress)

            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.24, weight: .bold))
                .foregroundColor(.black)
        }
    }
}

// MARK: - Day Chip

private struct DayChip: View {
    let day: RoutineDay
    let dayIndex: Int
    let isToday: Bool
    let isSelected: Bool
    let dateLabel: String
    let progress: [Int]
    let onTap: () -> Void

    private let accent = Color(hex: "#FDD835")
    private let chipSize: CGFloat = 72

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("Día \(day.dayNumber)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#171712"))
                if !dateLabel.isEmpty {
                    Text(dateLabel)
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "#171712").opacity(isToday ? 0.7 : 0.5))
                }
            }
            .frame(width: chipSize, height: chipSize)
            .background(isToday ? accent : Color.white)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        isSelected && !isToday ? accent :
                            (!isToday && !isSelected ? Color(hex: "#D6D6D6") : Color.clear),
                        lineWidth: 1.5
                    )
            )
        }
    }
}

// MARK: - Rest Day View

private struct RestDayView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bed.double.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
            Text("Hoy es día de descanso")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

// MARK: - Exercise Card

private struct ExerciseCard: View {
    let exercise: RoutineExercise
    var machine: Machine? = nil
    let isCompleted: Bool
    let isMissed: Bool
    let onTap: () -> Void

    private var coverUrl: String? {
        machine?.defaultVideos.first(where: { $0.title == exercise.videoTitle })?.cover
    }

    private var isPast: Bool { isMissed }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // 80x80 thumbnail
                ZStack {
                    if let url = coverUrl, let imageUrl = URL(string: url) {
                        AsyncImage(url: imageUrl) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                Color(hex: "#F0F0F0")
                            }
                        }
                    } else {
                        ZStack {
                            Color(hex: "#F0F0F0")
                            Image(systemName: "dumbbell.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.gray.opacity(0.4))
                        }
                    }
                }
                .frame(width: 80, height: 80)
                .clipped()
                .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    // Location tag
                    if let location = machine?.location, !location.isEmpty {
                        Text("📍 \(location)")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#171712"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(hex: "#F3F3F3"))
                            .cornerRadius(8)
                    }

                    // Machine name
                    Text(exercise.machineName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "#171712"))
                        .lineLimit(1)

                    // Video title
                    Text(exercise.videoTitle)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#171712").opacity(0.6))
                        .lineLimit(1)

                    // Sets x reps
                    Text(exerciseDetail)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#171712").opacity(0.6))
                }

                Spacer()

                // Status icon
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "#4CAF50"))
                } else if isMissed {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "#BBBBBB"))
                } else {
                    Circle()
                        .stroke(Color(hex: "#D6D6D6"), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(12)
            .background(isPast ? Color(hex: "#F5F5F0") : Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
            .opacity(isPast ? 0.45 : 1.0)
        }
    }

    private var exerciseDetail: String {
        let setsReps = "\(exercise.sets)×\(exercise.reps)"
        if exercise.weight > 0 {
            let w = exercise.weight.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", exercise.weight)
                : String(format: "%.1f", exercise.weight)
            return "\(setsReps) · \(w) kg"
        }
        return setsReps
    }
}

// MARK: - Exercise Detail Sheet

struct ExerciseDetailSheet: View {
    let exercise: RoutineExercise
    let dayIndex: Int
    let exerciseIndex: Int
    @ObservedObject var routineVM: RoutineViewModel
    let gymId: String
    let gymColor: Color
    let isToday: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var showVideoPlayer = false
    @State private var completedSuccessfully = false
    @State private var selectedVideo: Video?

    private var isAlreadyCompleted: Bool {
        routineVM.selectedDayProgress.contains(exerciseIndex)
    }

    private var coverUrl: String? {
        routineVM.selectedMachine?.defaultVideos
            .first(where: { $0.title == exercise.videoTitle })?.cover
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Machine header
                    HStack(spacing: 14) {
                        AsyncImage(url: URL(string: coverUrl ?? routineVM.selectedMachine?.imageUrl ?? "")) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                            default:
                                ZStack {
                                    Color(hex: "#E0E0E0")
                                    Image(systemName: "dumbbell.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 28, height: 28)
                                        .foregroundColor(.gray.opacity(0.5))
                                }
                            }
                        }
                        .frame(width: 80, height: 80)
                        .clipped()
                        .cornerRadius(12)

                        VStack(alignment: .leading, spacing: 4) {
                            // Location pill
                            if let location = routineVM.selectedMachine?.location, !location.isEmpty {
                                Text("📍 \(location)")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "#171712"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(hex: "#F3F3F3"))
                                    .cornerRadius(8)
                            }
                            Text(exercise.machineName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: "#171712"))
                            Text(exercise.videoTitle)
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#171712").opacity(0.6))
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)

                    // Stat boxes
                    HStack(spacing: 12) {
                        StatBox(title: "SERIES", value: "\(exercise.sets)")
                        StatBox(title: "REPS", value: "\(exercise.reps)")
                        StatBox(title: "PESO", value: weightText(exercise.weight))
                    }
                    .padding(.horizontal)

                    // Ver video button
                    if routineVM.isLoadingMachine {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if let machine = routineVM.selectedMachine,
                              let firstVideo = machine.defaultVideos.first {
                        Button {
                            selectedVideo = firstVideo
                        } label: {
                            HStack {
                                Image(systemName: "play.circle")
                                    .font(.system(size: 18))
                                Text("Ver video")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(hex: "#D6D6D6"), lineWidth: 1.5)
                            )
                        }
                        .padding(.horizontal)
                    }

                    // Complete exercise button
                    if isToday && !isAlreadyCompleted {
                        Button {
                            completeExercise()
                        } label: {
                            HStack {
                                if routineVM.isCompletingExercise {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .frame(width: 20, height: 20)
                                } else if completedSuccessfully {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                    Text("¡Completado!")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "checkmark.circle")
                                        .font(.system(size: 20))
                                    Text("Completar ejercicio")
                                        .font(.system(size: 16, weight: .bold))
                                }
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.accentColor)
                            .cornerRadius(16)
                        }
                        .disabled(routineVM.isCompletingExercise || completedSuccessfully)
                        .padding(.horizontal)
                    } else if isAlreadyCompleted {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                            Text("Ejercicio completado")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "#4CAF50"))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
            .navigationTitle("Detalle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.light)
        .fullScreenCover(item: $selectedVideo) { video in
            if (video.segments ?? []).isEmpty {
                VideoPlayerView(video: video) {
                    selectedVideo = nil
                }
            } else {
                SegmentedVideoPlayerView(
                    video: video,
                    gymColor: gymColor,
                    onDismiss: { selectedVideo = nil },
                    onAllSegmentsFinished: {}
                )
            }
        }
    }

    private func completeExercise() {
        guard let routine = routineVM.routine else { return }
        let day = routine.days[safe: dayIndex]
        let dayNumber = day?.dayNumber ?? (dayIndex + 1)

        routineVM.completeExercise(
            dayNumber: dayNumber,
            exerciseIndex: exerciseIndex,
            gymId: gymId,
            exercise: exercise
        ) { success in
            if success {
                completedSuccessfully = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    dismiss()
                }
            }
        }
    }

    private func weightText(_ weight: Double) -> String {
        if weight == 0 { return "Corporal" }
        return String(format: weight.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f kg" : "%.1f kg", weight)
    }
}

// MARK: - Stat Box

private struct StatBox: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
                .tracking(1)
            Text(value)
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(hex: "#F3F3F3"))
        .cornerRadius(12)
    }
}

// MARK: - Array safe subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
