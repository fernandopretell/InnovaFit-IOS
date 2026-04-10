import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @ObservedObject var viewModel: AuthViewModel
    @ObservedObject var routineVM: RoutineViewModel
    @ObservedObject var machineVM: MachineViewModel

    var onSelectMachine: (Machine, Gym) -> Void
    var onNavigateToSearch: () -> Void
    var onNavigateToRoutine: () -> Void

    @State private var selectedType: String = "Todos"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let profile = viewModel.userProfile {
                    // Header
                    HStack {
                        Text("Hola, \(profile.name.components(separatedBy: " ").first ?? profile.name) 👋")
                            .font(.title2.bold())
                            .foregroundColor(.textTitle)

                        Spacer()

                        Button(action: onNavigateToSearch) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.textTitle)
                        }
                        .padding(.trailing, 8)

                        Menu {
                            Button("Cerrar sesión", role: .destructive) {
                                viewModel.signOut()
                            }
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.textTitle)
                        }
                    }
                    .padding(.top)

                    // Routine banner
                    if let routine = routineVM.routine {
                        if routineVM.isRoutineStarted {
                            RoutineBannerCard(
                                routine: routine,
                                routineVM: routineVM,
                                onTap: onNavigateToRoutine
                            )
                        } else {
                            StartRoutineBannerCard(
                                routine: routine,
                                onTap: onNavigateToRoutine
                            )
                        }
                    }

                    // Gym subtitle
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Estas son las máquinas disponibles en")
                            .font(.body)
                            .foregroundColor(Color(hex: "#171712"))
                        (
                            Text("📍 ")
                            + Text(profile.gym?.name ?? "").fontWeight(.bold)
                        )
                        .font(.body)
                        .foregroundColor(Color(hex: "#171712"))
                    }

                    // Filter chips
                    MachineFilterChips(
                        machines: machineVM.machines,
                        selectedType: $selectedType
                    )

                    // Machine grid
                    if let gym = profile.gym {
                        let filtered = selectedType == "Todos"
                            ? machineVM.machines
                            : machineVM.machines.filter { $0.type.trimmingCharacters(in: .whitespaces) == selectedType }

                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(filtered) { machine in
                                Button {
                                    onSelectMachine(machine, gym)
                                } label: {
                                    MachineGridCard(machine: machine)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top)
            .task(id: viewModel.userProfile?.gymId) {
                if let gymId = viewModel.userProfile?.gymId {
                    machineVM.loadMachines(forGymId: gymId)
                }
            }
            .task(id: viewModel.userProfile?.id) {
                if let userId = viewModel.userProfile?.id {
                    routineVM.loadRoutine(userId: userId)
                }
            }
        }
        .background(Color(hex: "#FBFCF8").ignoresSafeArea())
    }
}

// MARK: - Routine Banner (active/started)

struct RoutineBannerCard: View {
    let routine: Routine
    @ObservedObject var routineVM: RoutineViewModel
    let onTap: () -> Void

    private let accent = Color(hex: "#FDD835")

    private var todayDay: RoutineDay? {
        routine.days[safe: routineVM.todayDayIndex]
    }

    private var dayLabel: String {
        guard let day = todayDay else { return "" }
        let num = day.dayNumber
        if day.isRest { return "Día \(num): Descanso" }
        let label = day.label.isEmpty ? (routine.objective.isEmpty ? "Entrenamiento" : routine.objective) : day.label
        return "Día \(num): \(label)"
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    // Yellow dot + RUTINA ACTIVA
                    HStack(spacing: 6) {
                        Circle().fill(accent).frame(width: 8, height: 8)
                        Text("RUTINA ACTIVA")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(accent)
                            .tracking(1)
                    }

                    // Day label
                    Text(dayLabel)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    // Weekly progress circles
                    let stats = routineVM.weeklyStats
                    if !stats.weeklyProgress.isEmpty {
                        HStack(spacing: 12) {
                            ForEach(Array(stats.weeklyProgress.enumerated()), id: \.offset) { index, progress in
                                VStack(spacing: 4) {
                                    ZStack {
                                        Circle()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 3)
                                            .frame(width: 28, height: 28)
                                        Circle()
                                            .trim(from: 0, to: CGFloat(max(0, progress)))
                                            .stroke(accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                            .rotationEffect(.degrees(-90))
                                            .frame(width: 28, height: 28)
                                        Text(progress >= 0 ? "\(Int(progress * 100))" : "--")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(index == stats.currentWeekIndex ? accent : Color.clear, lineWidth: 1.5)
                                            .frame(width: 32, height: 32)
                                    )

                                    Text("S\(stats.windowStart + index + 1)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                    }

                    // Streak
                    if stats.streak > 0 {
                        Text("🔥 Racha: \(stats.streak) semana\(stats.streak > 1 ? "s" : "") al 80%+")
                            .font(.system(size: 11))
                            .foregroundColor(accent.opacity(0.9))
                    }
                }

                Spacer()

                // Ver Rutina button
                Text("Ver Rutina →")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(accent)
                    .cornerRadius(24)
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#2A2A2A"), Color(hex: "#1A1A1A")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
        }
    }
}

// MARK: - Start Routine Banner

struct StartRoutineBannerCard: View {
    let routine: Routine
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("NUEVA RUTINA")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.black.opacity(0.6))
                        .tracking(1.5)

                    Text(routine.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(2)

                    Text("\(routine.durationWeeks) semanas · \(routine.days.count) días")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }

                Spacer()

                Text("Iniciar →")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .cornerRadius(20)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(18)
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Filter Chips

private struct MachineFilterChips: View {
    let machines: [Machine]
    @Binding var selectedType: String

    private var types: [String] {
        let machineTypes = machines
            .map { $0.type.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let unique = Array(Set(machineTypes)).sorted()
        return ["Todos"] + unique
    }

    var body: some View {
        if types.count > 1 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(types, id: \.self) { type in
                        let isSelected = selectedType == type
                        Button {
                            selectedType = type
                        } label: {
                            Text(type)
                                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(Color(hex: "#171712"))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isSelected ? Color(hex: "#FDD835") : Color(hex: "#F4F2E6"))
                                .cornerRadius(20)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Machine Grid Card

private struct MachineGridCard: View {
    let machine: Machine

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: URL(string: machine.imageUrl)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit()
                default:
                    ZStack {
                        Color(hex: "#F0F0F0")
                        Image(systemName: "dumbbell.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .foregroundColor(.gray.opacity(0.4))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .padding(.horizontal, 16)
            .padding(.top, 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(machine.name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#171712"))
                    .lineLimit(2)

                if let location = machine.location, !location.isEmpty {
                    HStack(spacing: 2) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 8))
                        Text(location)
                            .font(.system(size: 11))
                            .lineLimit(1)
                    }
                    .foregroundColor(Color(hex: "#171712"))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
    }
}
