import SwiftUI
import Charts
import UIKit

struct MuscleHistoryView: View {
    @StateObject private var viewModel = MuscleHistoryViewModel()
    @State private var isPresentingCamera = false
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false
    @State private var showSelfiePreview = false
    @State private var isProcessingSelfie = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
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

                if isProcessingSelfie {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView("Generando...")
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(12)
                }
            }
            .sheet(isPresented: $isPresentingCamera) {
                SelfieCameraView { image in
                    processSelfie(image)
                }
            }
            .sheet(isPresented: $showSelfiePreview) {
                if let shareImage = shareImage {
                    SharePreview(image: shareImage) {
                        showShareSheet = true
                    }
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
    private func processSelfie(_ image: UIImage) {
        isProcessingSelfie = true
        Task {
            let bgRemoved = await image.removingBackground() ?? image
            let composed = createShareImage(selfie: bgRemoved)
            await MainActor.run {
                self.shareImage = composed
                self.isProcessingSelfie = false
                self.showSelfiePreview = true
            }
        }
    }

    private func createShareImage(selfie: UIImage) -> UIImage {
        let targetSize = CGSize(width: 1080, height: 1920)
        let cardView = ShareCardView(selfie: selfie, logs: viewModel.logs)
        return cardView.asImage(size: targetSize)
    }
}

private struct ShareCardView: View {
    let selfie: UIImage
    let logs: [ExerciseLog]

    var body: some View {
        ZStack {
            Image("AppLogo1")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Image(uiImage: selfie)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 10)
                .padding()

            VStack {
                Spacer()
                Text("Sesiones esta semana: \(logs.count)")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(12)
                    .padding(.bottom, 40)
            }
        }
    }
}

private struct SharePreview: View {
    let image: UIImage
    var onShare: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()

            Button("Compartir") {
                dismiss()
                onShare()
            }
            .padding()
        }
    }
}

private extension View {
    func asImage(size: CGSize) -> UIImage {
        let controller = UIHostingController(rootView: self)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .clear
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

