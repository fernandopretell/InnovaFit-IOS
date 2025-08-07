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
typealias Logs = [ExerciseLog]

struct ShareCardView: View {
    @StateObject private var viewModel: MuscleHistoryViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false

    init(viewModel: MuscleHistoryViewModel = MuscleHistoryViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var logs: Logs { viewModel.logs }

    // Segmentos ordenados por mayor conteo
    private var segments: [MuscleSegment] {
        var counts: [String: Int] = [:]
        logs.forEach { counts[$0.mainMuscle, default: 0] += 1 }

        let palette: [Color] = [.orange, .blue, .green, .red, .purple]
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

    private var totalCount: Int { segments.map(\.count).reduce(0, +) }

    // Destacado = grupo con mayor porcentaje (el primero de 'segments')
    private var featuredExercise: String {
        segments.first?.muscle ?? ""
    }

    var body: some View {
        
        
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 12) {
                // Top bar FUERA del card
                topBar

                // Card
                cardContent
            }
            .foregroundStyle(.white)
        }
        .onAppear { viewModel.fetchLogs() }
        .sheet(isPresented: $showShareSheet) {
            if let shareImage {
                ShareSheet(items: [shareImage])
            }
        }
    }

    // MARK: - Top Bar (fuera del card)
    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .symbolRenderingMode(.monochrome)
            }

            Spacer()

            Button {
                shareImage = cardContent.asImage(size: CGSize(width: 330, height: 600))
                showShareSheet = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .bold))
                    .symbolRenderingMode(.monochrome)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .foregroundStyle(.white)  // ← todos los íconos/textos en blanco
        .tint(.white)             // ← por si algún control usa tint
    }


    // MARK: - Card
    private var cardContent: some View {
        ZStack {
            // Fondo del card
            Color.accentColor
            content

            /*if logs.isEmpty {
                emptyState
            } else {
                content
            }*/
        }
        .frame(width: 330, alignment: .center)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .overlay(alignment: .top) {
            gymBadge
                .offset(y: -26) // ~mitad fuera
                .zIndex(1)
        }
        .fixedSize(horizontal: false, vertical: true)
        // Pastilla del gimnasio: mitad saliendo por arriba
        
    }

    // MARK: - Pastilla gimnasio (más grande)
    private var gymBadge: some View {
        Text(authViewModel.userProfile?.gym?.name ?? "")
            .font(.title3.weight(.black)) // más grande
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .background(Color.white.cornerRadius(12))
            .foregroundColor(.black)
    }

    // MARK: - Estado vacío
    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("Aún no te has ejercitado esta semana")
                .font(.title2).bold()
                .multilineTextAlignment(.center)

            Text("¡Comienza a entrenar para ver tu progreso aquí!")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)

            Button(action: {}) {
                Text("Empezar ahora")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue.cornerRadius(10))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Contenido (SIN Scroll)
    private var content: some View {
        VStack(spacing: 32) {
            // Dejamos espacio porque la pastilla del gym sale por arriba
            Spacer().frame(height: 32)

            VStack(spacing: 6){
                greetingText
                titleText
                subtitleText
            }

            donutChart
            legendView
            featuredExerciseView
            footer

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
    }

    private var greetingText: some View {
        let name = authViewModel.userProfile?.name ?? ""
        return (
            Text("Hola ")
            + Text(name).fontWeight(.bold)
            + Text(", esta es tu")
        )
        .font(.subheadline)
        .foregroundColor(.black.opacity(0.85))
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var titleText: some View {
        Text("Evolución semanal")
            .font(.title.bold())
            .foregroundColor(.black)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private var subtitleText: some View {
        Text("durante esta semana rompiste tu récord personal…")
            .font(.footnote)
            .foregroundColor(.black.opacity(0.8))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
    }

    private var donutChart: some View {
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
        .frame(height: 180) // baja un poco para que todo encaje
        .chartBackground { proxy in
            VStack(spacing: 0) {
                Text("\(totalCount)")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.black)
                Text("Ejercicios")
                    .font(.footnote).bold()
            }
            .frame(width: proxy.plotSize.width,
                   height: proxy.plotSize.height,
                   alignment: .center)
        }
    }

    private var legendView: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(segments) { seg in
                HStack(spacing: 6) {
                    Circle()
                        .fill(seg.color)
                        .frame(width: 10, height: 10)
                    Text("\(seg.muscle) \(Int(round((Double(seg.count) / max(1, Double(totalCount))) * 100)))%")
                        .font(.caption)
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    // Pastilla que se ajusta al contenido (24 de padding), centrada
    private var featuredExerciseView: some View {
        HStack {
            VStack(spacing: 4) {
                Text("Tu ejercicio destacado de la semana")
                    .font(.caption)
                    .foregroundColor(.white)
                Text(featuredExercise)
                    .font(.title3)
                    .fontWeight(.heavy)
                    .foregroundColor(.accentColor)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.black.cornerRadius(12))
        }
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Text("Entrena con")
                .font(.caption)
                .foregroundColor(.black)
            Image("AppLogoBlack")
                .resizable()
                .scaledToFit()
                .frame(width: 85, height: 20)
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Snapshot helper
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
