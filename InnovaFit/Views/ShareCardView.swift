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
    private var segments: [MuscleSegment] {
        var counts: [String: Int] = [:]
        logs.forEach { log in
            counts[log.mainMuscle, default: 0] += 1
        }

        let palette: [Color] = [.orange, .blue, .green, .red, .purple]
        return counts.sorted { $0.value > $1.value }
            .enumerated()
            .map { idx, entry in
                MuscleSegment(muscle: entry.key, count: entry.value,
                              color: palette[idx % palette.count])
            }
    }
    private var totalCount: Int { segments.map(\.count).reduce(0, +) }
    private var featuredExercise: String {
        logs.sorted { $0.timestamp > $1.timestamp }
            .first?.mainMuscle ?? ""
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            cardContent
                .onAppear { viewModel.fetchLogs() }

            Button {
                shareImage = cardContent.asImage(size: CGSize(width: 330, height: 600))
                showShareSheet = true
            } label: {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
            }
            .padding()
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareImage {
                ShareSheet(items: [shareImage])
            }
        }
    }

    private var cardContent: some View {
        ZStack {
            Color(Color.accentColor).edgesIgnoringSafeArea(.all)

            if logs.isEmpty {
                emptyState
            } else {
                content
            }
        }
        .frame(width: 330, height: 600)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }

    // MARK: - Estado vacío
    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("Aún no te has ejercitado esta semana")
                .font(.title2).bold()
                .multilineTextAlignment(.center)

            Text("¡Comienza a entrenar para ver tu progreso aquí!")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)

            Button(action: {
                // Acción sugerida: navegar a la pantalla de ejercicios
            }) {
                Text("Empezar ahora")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.cornerRadius(8))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 32)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Contenido con datos
    private var content: some View {
        ScrollView {
            VStack(spacing: 28) {
                Text(authViewModel.userProfile?.gym?.name ?? "")
                    .font(.subheadline).bold()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.white.cornerRadius(12))
                    .foregroundColor(.black)

                VStack(spacing: 8){
                    greetingText
                    titleText
                    subtitleText
                }
                .padding(.top, 8)

                donutChart
                legendView
                featuredExerciseView
                footer
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
    }

    private var greetingText: some View {
        let name = authViewModel.userProfile?.name ?? ""
        return (
            Text("Hola ")
            + Text(name).fontWeight(.bold)
            + Text(", esta es tu")
        )
        .font(.subheadline)
        .foregroundColor(.black.opacity(0.8))
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var titleText: some View {
        Text("Evolución semanal")
            .font(.largeTitle).bold()
            .foregroundColor(.black)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private var subtitleText: some View {
        Text("durante esta semana rompiste tu récord personal…")
            .font(.subheadline)
            .foregroundColor(.black.opacity(0.8))
            .multilineTextAlignment(.center)
            .padding(.horizontal)
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
        .frame(height: 200)
        .chartBackground { proxy in
            VStack(spacing: 0) {
                Text("\(totalCount)")
                    .font(.system(size: 48, weight: .bold))
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
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
            ForEach(segments) { seg in
                HStack(spacing: 6) {
                    Circle()
                        .fill(seg.color)
                        .frame(width: 10, height: 10)
                    Text("\(seg.muscle) \(Int(Double(seg.count)/Double(totalCount)*100))%")
                        .font(.caption)
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var featuredExerciseView: some View {
        HStack {
            VStack(spacing: 4) {
                Text("Tu ejercicio destacado de la semana")
                    .font(.caption)
                    .foregroundColor(.white)
                Text(featuredExercise)
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundColor(.accentColor)
                    .multilineTextAlignment(.center)
            }
            .padding(18)
            .background(Color.black.cornerRadius(12))
        }
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        HStack {
            Text("Entrena con")
                .font(.caption)
                .foregroundColor(.black)
            Image("AppLogoBlack")
                .resizable()
                .scaledToFit()
                .frame(width: 85)
        }
        .padding(.bottom, 16)
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
