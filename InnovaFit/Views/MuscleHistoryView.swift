import SwiftUI
import Charts

struct MuscleHistoryView: View {
    @StateObject private var viewModel = MuscleHistoryViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                pieChartSection
                recentSection
            }
            .padding()
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear { viewModel.fetchLogs() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Historial de músculos entrenados")
                .font(.title2.bold())
                .foregroundColor(.textTitle)
            Text("Revisa qué grupos musculares has trabajado en tus sesiones.")
                .font(.subheadline)
                .foregroundColor(.textSubtitle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var pieChartSection: some View {
        VStack(alignment: .leading) {
            if viewModel.logs.isEmpty {
                Text("Sin registros disponibles")
                    .font(.subheadline)
                    .foregroundColor(.textBody)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(viewModel.muscleDistribution) { item in
                    SectorMark(angle: .value("Sesiones", item.count))
                        .foregroundStyle(item.color)
                }
                .chartLegend(.hidden)
                .frame(height: 220)
                .overlay(
                    Text("\(viewModel.logs.count)")
                        .font(.title.bold())
                        .foregroundColor(.textTitle)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sesiones recientes")
                .font(.headline)
                .foregroundColor(.textTitle)
            ForEach(viewModel.recentLogs) { log in
                SessionRow(log: log)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SessionRow: View {
    let log: ExerciseLog

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "dumbbell")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .padding(6)
                .background(Color.backgroundFields)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(log.machineName)
                    .font(.subheadline.bold())
                    .foregroundColor(.textTitle)
                Text(log.muscleGroups.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.textBody)
                Text(log.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.textSubtitle)
            }
            Spacer()
            VStack(spacing: 12) {
                Button {
                    // Acción para volver a la rutina
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                ShareLink(item: "Entrené \(log.videoTitle)") {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .buttonStyle(BorderlessButtonStyle())
            .foregroundColor(.accentColor)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
}

#Preview {
    MuscleHistoryView()
}
