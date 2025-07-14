import SwiftUI
import Charts

struct MuscleHistoryView: View {
    @StateObject private var viewModel = MuscleHistoryViewModel()

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                        .padding(.top, geo.safeAreaInsets.top)
                    pieChartSection
                    recentSection
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .background(Color(hex: "#F8F9FA").ignoresSafeArea())
            .onAppear { viewModel.fetchLogs() }
        }
    }

    // Header bajo el notch
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Historial semanal")
                .font(.title2.bold())
                .foregroundColor(.textTitle)
            Text("Revisa qué grupos musculares has trabajado esta semana.")
                .font(.subheadline)
                .foregroundColor(.textSubtitle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Pie chart con leyenda a la derecha
    private var pieChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Distribución por grupo muscular")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.textTitle)
                .padding(.top, 4)
                .padding(.bottom, 8)

            GeometryReader { geo in
                let cardHeight = geo.size.height
                let cardWidth = geo.size.width
                let donutSize = min(cardHeight * 0.90, cardWidth * 0.36) // ¡No más de 90% del alto ni 36% del ancho!

                HStack(alignment: .center, spacing: 0) {
                    Spacer(minLength: 12) // Margen izquierdo

                    ZStack {
                        DonutChartView(
                            segments: viewModel.donutSegments,
                            total: viewModel.logs.count
                        )
                    }
                    .frame(width: donutSize, height: donutSize)

                    Spacer(minLength: 8) // Margen entre donut y leyenda

                    muscleLegend(for: viewModel)
                        .frame(width: cardWidth * 0.54, alignment: .trailing)
                }

            }
            .frame(height: 170) // O más si quieres aún más margen
            .clipped()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }



    // Donut Chart (con texto en el centro)
    private func donutChart(for viewModel: MuscleHistoryViewModel) -> some View {
        ZStack {
            DonutChartView(
                segments: viewModel.donutSegments,
                total: viewModel.logs.count
            )
        }
        .frame(width: 130, height: 130)
    }

    // Leyenda a la derecha (texto negro)
    private func muscleLegend(for viewModel: MuscleHistoryViewModel) -> some View {
        VStack(alignment: .leading, spacing: 18) { // <--- aquí cambio a .leading
            ForEach(viewModel.muscleDistribution.prefix(4)) { item in
                HStack(spacing: 8) {
                    Circle()
                        .fill(item.color)
                        .frame(width: 12, height: 12)
                    Text("\(item.muscle) (\(item.percentString(total: viewModel.logs.count)))")
                        .font(.caption)
                        .foregroundColor(item.color == Color(hex: "#E1E1E1") ? .gray : .black)
                }
            }
            if viewModel.muscleDistribution.count > 4 {
                let othersCount = viewModel.logs.count -
                    viewModel.muscleDistribution.prefix(4).map { $0.count }.reduce(0, +)
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: "#E1E1E1"))
                        .frame(width: 12, height: 12)
                    Text("Otros (\(Int(round(Double(othersCount)/Double(viewModel.logs.count)*100)))%)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing) // <--- aquí se alinea TODO el bloque a la derecha
    }


    // Sesiones recientes
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

// MARK: - Row de sesión

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

