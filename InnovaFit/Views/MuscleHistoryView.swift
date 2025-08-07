import SwiftUI
import Charts
import UIKit

struct MuscleHistoryView: View {
    @StateObject private var viewModel = MuscleHistoryViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showShareCard = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header(geo: geo)
                        pieChartSection
                        recentSection
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
                .background(Color(hex: "#F5F5F5").ignoresSafeArea())
                .onAppear { viewModel.fetchLogs() }
            }
            .fullScreenCover(isPresented: $showShareCard) {
                ShareCardView(viewModel: viewModel)
                    .environmentObject(authViewModel)
            }
        }
    }

    // Header bajo el notch, con botón compartir a la derecha
    private func header(geo: GeometryProxy) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Historial semanal")
                    .font(.title)
                    .fontWeight(.heavy)
                    .foregroundColor(.textTitle)
                Text("Revisa qué grupos musculares has trabajado esta semana.")
                    .font(.subheadline)
                    .foregroundColor(.textSubtitle)
            }
            Spacer()
            Button {
                showShareCard = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.textTitle)
            }
        }
        .padding(.horizontal)
        .padding(.top, geo.safeAreaInsets.top + 8)
    }


    // Pie chart con leyenda a la derecha y donut centrado verticalmente
    private var pieChartSection: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Distribución por grupo muscular")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.textTitle)
                .padding(.top, 4)
                .padding(.bottom, 8)

            GeometryReader { geo in
                let cardHeight = geo.size.height
                let cardWidth = geo.size.width
                let donutSize = min(cardHeight * 0.82, cardWidth * 0.36) // Ajuste seguro

                HStack(alignment: .center, spacing: 0) {
                    Spacer(minLength: 12) // Margen izquierdo

                    VStack {
                        Spacer()
                        ZStack {
                            DonutChartView(
                                segments: viewModel.donutSegments,
                                total: viewModel.logs.count
                            )
                        }
                        .frame(width: donutSize, height: donutSize)
                        Spacer()
                    }
                    .frame(height: geo.size.height)

                    Spacer(minLength: 8) // Margen entre donut y leyenda

                    muscleLegend(for: viewModel)
                        .frame(width: cardWidth * 0.54, alignment: .trailing)
                }
            }
            .frame(height: 170)
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
    }

    // Leyenda a la derecha (alineada pro)
    private func muscleLegend(for viewModel: MuscleHistoryViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(viewModel.muscleDistribution.prefix(4)) { item in
                HStack(spacing: 5) {
                    Circle()
                        .fill(item.color)
                        .frame(width: 12, height: 12)
                    Text("\(item.muscle) (\(item.percentString(total: viewModel.logs.count)))")
                        .font(.caption)
                        .foregroundColor(item.color == Color(hex: "#F3F4F6") ? .black : .black)
                }
            }
            if viewModel.muscleDistribution.count > 4 {
                let othersCount = viewModel.logs.count -
                    viewModel.muscleDistribution.prefix(4).map { $0.count }.reduce(0, +)
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color(hex: "#F3F4F6"))
                        .frame(width: 12, height: 12)
                    Text("Otros (\(Int(round(Double(othersCount)/Double(viewModel.logs.count)*100)))%)")
                        .font(.caption)
                        .foregroundColor(.black)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // Sesiones recientes
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sesiones recientes")
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundColor(.textTitle)

                Spacer()
            }

            ForEach(viewModel.recentLogs) { log in
                SessionRow(
                    log: log,
                    muscleColor: viewModel.color(for: log.mainMuscle)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Row de sesión
struct SessionRow: View {
    let log: ExerciseLog
    let muscleColor: Color

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                // Fecha relativa
                Text(log.timestamp.formatted(.relative(presentation: .named, unitsStyle: .abbreviated)))
                    .font(.caption2)
                    .foregroundColor(Color(.systemGray))
                
                // Título
                Text(log.machineName)
                    .font(.headline)
                    .fontWeight(.heavy)
                    .foregroundColor(.textTitle)
                
                // Ejercicio
                Text(log.videoTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textBody)
                
                // Músculo principal
                if !log.mainMuscle.isEmpty {
                    Text(log.mainMuscle)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(muscleColor)
                        .padding(.top, 2)
                }
            }
            
            Spacer(minLength: 8)
            
            // Imagen de la máquina
            AsyncImage(url: URL(string: log.machineImageUrl)) { phase in
                switch phase {
                case .empty:
                    // Placeholder mientras carga
                    ZStack {
                        Color(hex:"#CACCD3")                // fondo gris claro
                        ProgressView()                     // spinner centrado
                            .progressViewStyle(
                                CircularProgressViewStyle(tint: .gray) // spinner en gris oscuro
                            )
                            .scaleEffect(1.2)              // un poco más grande
                    }
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    // Icono de mancuerna si falla
                    ZStack {
                        Color(.systemGray2)
                        Image(systemName: "dumbbell.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.gray.opacity(0.7))
                    }
                @unknown default:
                    ZStack {
                        Color(.systemGray2)
                        ProgressView()
                            .progressViewStyle(
                                CircularProgressViewStyle(tint: .gray)
                            )
                            .scaleEffect(1.2)
                    }
                }
            }
            .frame(width: 70, height: 70)
            .cornerRadius(8)
            .clipped()

        }
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}


