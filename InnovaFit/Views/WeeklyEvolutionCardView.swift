import SwiftUI
import Charts
import UIKit

// MARK: - Modelo para la porción del donut
struct MuscleSegment: Identifiable {
    let id = UUID()
    let muscle: String
    let count: Int
    let color: Color
}

// MARK: - Vista principal de la tarjeta
struct WeeklyEvolutionCardView: View {

    @StateObject private var viewModel: MuscleHistoryViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    init(viewModel: MuscleHistoryViewModel = MuscleHistoryViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var logs: [ExerciseLog] {
        viewModel.logs
    }

    private var featuredExercise: String {
        logs.sorted { $0.timestamp > $1.timestamp }
            .first?.machineName ?? ""
    }

    private var segments: [MuscleSegment] {
        // Cuenta por músculo principal
        var counts: [String:Int] = [:]
        logs.forEach { log in
            if let m = log.muscleGroups.first {
                counts[m, default: 0] += 1
            }
        }
        let palette: [Color] = [ .orange, .blue, .green, .red, .purple ]
        return counts
            .sorted { $0.value > $1.value }
            .enumerated()
            .map { idx, entry in
                MuscleSegment(
                    muscle: entry.key,
                    count: entry.value,
                    color: palette[idx % palette.count]
                )
            }
    }

    private var totalCount: Int {
        segments.map(\.count).reduce(0, +)
    }

    var body: some View {
        ZStack {
            Color(hex: "#FFD600").edgesIgnoringSafeArea(.all)

            VStack(spacing: 16) {
                // Header con logo y gym
                Text(authViewModel.userProfile?.gym?.name ?? "")
                    .font(.subheadline).bold()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.white.cornerRadius(12))
                    .foregroundColor(.black)

                Text("Hola \(authViewModel.userProfile?.name ?? ""), esta es tu")
                    .font(.headline)
                    .foregroundColor(.black.opacity(0.8))

                Text("Evolución semanal")
                    .font(.largeTitle).bold()
                    .foregroundColor(.black)

                Text("durante esta semana rompiste tu récord personal…")
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                // Donut chart
                Chart {
                    ForEach(segments) { seg in
                        SectorMark(
                            angle: .value("Count", seg.count),
                            innerRadius: .ratio(0.6),
                            angularInset: 1
                        )
                        .foregroundStyle(seg.color)
                    }
                }
                .frame(height: 200)
                .chartBackground { proxy in
                    VStack(spacing: 0) {
                        Text("\(totalCount)")
                            .font(.system(size: 48, weight: .bold))
                        Text("Ejercicios")
                            .font(.footnote).bold()
                    }
                    .frame(width: proxy.plotSize.width,
                           height: proxy.plotSize.height,
                           alignment: .center)
                }

                // Leyenda
                HStack(spacing: 16) {
                    ForEach(segments.prefix(3)) { seg in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(seg.color)
                                .frame(width: 10, height: 10)
                            Text("\(seg.muscle) \(Int(Double(seg.count)/Double(totalCount)*100))%")
                                .font(.caption)
                                .foregroundColor(.black)
                        }
                    }
                }

                // Ejercicio destacado
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ejercicio destacado")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Text(featuredExercise)
                            .font(.headline).bold()
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding()
                .background(Color.black.cornerRadius(12))
                .padding(.horizontal, 24)

                // Botón CTA
                Button(action: {
                    // Acción
                }) {
                    Text("Entrena con InnovaFit")
                        .font(.headline).bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(24)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .padding(.top, 16)
        }
        .frame(width: 330, height: 700)
        .cornerRadius(32)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .onAppear {
            viewModel.fetchLogs()
        }
    }
}

// MARK: - Preview
struct WeeklyEvolutionCardView_Previews: PreviewProvider {
    static var previews: some View {
        // Creamos 5 logs de Cuádriceps y 3 de Aductores
        let quadLogs: [ExerciseLog] = (1...5).map { index in
            ExerciseLog(
                id: "quad-\(index)",
                machineId: "legpress",
                machineName: "Leg Press \(index)",
                machineImageUrl: "https://placekitten.com/200/200",
                muscleGroups: ["Cuádriceps"],
                timestamp: Date().addingTimeInterval(Double(-index * 3600)),
                userId: "user123",
                videoId: "vid_quad_\(index)",
                videoTitle: "Press de Piernas \(index)"
            )
        }

        let adductorLogs: [ExerciseLog] = (1...3).map { index in
            ExerciseLog(
                id: "adduct-\(index)",
                machineId: "adductor",
                machineName: "Adductor Machine \(index)",
                machineImageUrl: "https://placekitten.com/200/200",
                muscleGroups: ["Aductores"],
                timestamp: Date().addingTimeInterval(Double(-index * 7200)),
                userId: "user123",
                videoId: "vid_adduct_\(index)",
                videoTitle: "Aductores \(index)"
            )
        }

        let sampleLogs = quadLogs + adductorLogs

        let viewModel = MuscleHistoryViewModel()
        viewModel.logs = sampleLogs

        return WeeklyEvolutionCardView(viewModel: viewModel)
            .environmentObject(AuthViewModel())
            .previewLayout(.sizeThatFits)
            .padding()
    }
}




