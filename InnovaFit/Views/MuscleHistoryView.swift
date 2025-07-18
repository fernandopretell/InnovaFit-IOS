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
                        header(geo: geo)
                        pieChartSection
                        recentSection
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
                .background(Color(hex: "#F5F5F5").ignoresSafeArea())
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
                ShareCardView(name: "selfie", logs: viewModel.logs, gymName: "Mike Gym", featuredExercise: "Cuadriceps" )
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
                isPresentingCamera = true
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
        let cardView = ShareCardView(name: "selfie", logs: viewModel.logs, gymName: "Mike Gym", featuredExercise: "Cuadriceps" )
        return cardView.asImage(size: targetSize)
    }
}

struct MuscleShareShareCard: Identifiable {
    let id = UUID()
    let muscle: String
    let percentage: Double
    let color: Color
}

struct ShareCardView: View {
    let name: String
    let logs: [ExerciseLog]
    let gymName: String
    let featuredExercise: String

    // Cálculo de la distribución (porcentaje) de los músculos
    private var muscleDistribution: [MuscleShareShareCard] {
        // Cuenta sesiones por músculo principal
        var counts: [String: Int] = [:]
        for log in logs {
            if let m = log.muscleGroups.first {
                counts[m, default: 0] += 1
            }
        }
        let total = counts.values.reduce(0, +)
        // Asignamos colores a los primeros 3 músculos
        let palette: [Color] = [.orange, .blue, .green]
        return counts
            .sorted { $0.value > $1.value }
            .enumerated()
            .prefix(3)
            .map { idx, entry in
                MuscleShareShareCard(
                    muscle: entry.key,
                    percentage: total > 0 ? Double(entry.value) / Double(total) * 100 : 0,
                    color: palette[idx]
                )
            }
    }

    var body: some View {
        ZStack {
            // Fondo amarillo de marca
            Color(hex: "#FDD835")
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // Logo + nombre de gimnasio
                VStack(spacing: 4) {
                    Image("innovafitLogo")      // asset con el logo
                        .resizable()
                        .scaledToFit()
                        .frame(height: 32)
                    Text(gymName)
                        .font(.subheadline).bold()
                        .foregroundColor(.black.opacity(0.7))
                }

                // Título principal
                Text("Evolución Semanal")
                    .font(.largeTitle).bold()
                    .foregroundColor(.black)

                // Mensaje personalizado
                Text("\(name), esta semana rompiste tu récord 💪")
                    .font(.headline)
                    .foregroundColor(.black.opacity(0.8))

                // Donut chart con número de sesiones
                Chart(muscleDistribution) { item in
                    SectorMark(
                        angle: .value("Porcentaje", item.percentage),
                        innerRadius: .ratio(0.6),
                        angularInset: 1
                    )
                    .foregroundStyle(item.color)
                }
                .chartBackground { proxy in
                    // Número total en el centro
                    VStack {
                        Text("\(logs.count)")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.black)
                        Text("Ejercicios")
                            .font(.footnote).bold()
                            .foregroundColor(.black.opacity(0.7))
                    }
                    .frame(width: proxy.plotSize.width,
                           height: proxy.plotSize.height,
                           alignment: .center)
                }
                .frame(height: 200)

                // Leyenda debajo del donut
                HStack(spacing: 16) {
                    ForEach(muscleDistribution) { item in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 10, height: 10)
                            Text("\(item.muscle) \(Int(item.percentage))%")
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
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding()
                .background(Color.black)
                .cornerRadius(12)
                .padding(.horizontal)

                // Botón de llamada a la acción
                Button(action: {
                    // acción de “Entrena con Innovafit”
                }) {
                    Text("Entrena con Innovafit")
                        .font(.headline).bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(24)
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .padding(.top, 16)
        }
        .frame(width: 330, height: 700)
        .cornerRadius(32)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
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

