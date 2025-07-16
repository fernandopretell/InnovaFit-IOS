import SwiftUI
import Charts
import UIKit

struct MuscleHistoryView: View {
    @StateObject private var viewModel = MuscleHistoryViewModel()
    @State private var isPresentingCamera = false
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false

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
            .sheet(isPresented: $isPresentingCamera) {
                SelfieCameraView { image in
                    let composed = createShareImage(selfie: image)
                    self.shareImage = composed
                    self.showShareSheet = true
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let shareImage = shareImage {
                    ShareSheet(items: [shareImage])
                }
            }
        }
    }

    // Header bajo el notch
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Historial semanal")
                .font(.title)
                .fontWeight(.heavy)
                .foregroundColor(.textTitle)
            Text("Revisa qué grupos musculares has trabajado esta semana.")
                .font(.subheadline)
                .foregroundColor(.textSubtitle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

                Button {
                    isPresentingCamera = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.textTitle)
                }
            }

            ForEach(viewModel.recentLogs) { log in
                SessionRow(
                    log: log,
                    muscleColor: viewModel.color(for: log.muscleGroups.first ?? "")
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
                if let mainMuscle = log.muscleGroups.first {
                    Text("\(mainMuscle)")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(muscleColor)
                        .padding(.top, 2)
                }
            }
            
            Spacer(minLength: 8)
            
            // Imagen de la máquina
            AsyncImage(url: URL(string: log.machineImageUrl)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(.systemGray5)
                }
            }
            .frame(width: 70, height: 70)
            .cornerRadius(8)
            .clipped()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Selfie Share helpers
extension MuscleHistoryView {
    private func createShareImage(selfie: UIImage) -> UIImage {
        // Placeholder composition. Background removal would be implemented here.
        let renderer = UIGraphicsImageRenderer(size: selfie.size)
        let statsText = "Sesiones: \(viewModel.logs.count)"
        return renderer.image { ctx in
            selfie.draw(in: CGRect(origin: .zero, size: selfie.size))

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: selfie.size.width * 0.07),
                .foregroundColor: UIColor.white,
                .paragraphStyle: {
                    let style = NSMutableParagraphStyle()
                    style.alignment = .center
                    return style
                }()
            ]

            let textRect = CGRect(x: 0,
                                   y: selfie.size.height - selfie.size.width * 0.2,
                                   width: selfie.size.width,
                                   height: selfie.size.width * 0.2)
            statsText.draw(in: textRect, withAttributes: attributes)
        }
    }
}

