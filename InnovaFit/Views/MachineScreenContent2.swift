import SwiftUI
import SwiftData

struct MachineScreenContent2: View {
    let machine: Machine
    let gym: Gym

    @Environment(\.dismiss) private var dismiss

    // Player
    @State private var selectedVideo: Video?
    @State private var pendingVideoToPlay: Video?

    // Feedback flags
    @Query private var feedbackFlags: [ShowFeedback]
    @AppStorage("hasWatchedAllVideos") var hasWatchedAllVideos: Bool = false
    @Environment(\.modelContext) private var context

    // UI states
    @State private var showFeedbackDialog = false
    @State private var showToast = false
    @State private var showExerciseToast = false

    // Dialogos
    @State private var showInfoSheet = false         // descripción de la máquina
    @State private var showRegisterChoice = false    // “Registrar y ver” / “Solo ver video”

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 16) {

                    // HEADER con imagen, título y botón info
                    ZStack(alignment: .bottomLeading) {
                        AsyncImage(url: URL(string: machine.imageUrl)) { image in
                            image.resizable()
                                .scaledToFill()
                                .frame(height: 240)
                                .clipped()
                                .cornerRadius(12)
                        } placeholder: {
                            Color.gray.opacity(0.1)
                                .frame(height: 240)
                                .cornerRadius(12)
                        }

                        // Gradiente inferior para lectura del título
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.8), .clear]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .cornerRadius(12)
                        .frame(height: 130)

                        // Botón info (arriba derecha)
                        HStack {
                            Spacer()
                            VStack {
                                Spacer()

                                Button {
                                    showInfoSheet = true
                                } label: {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.25))
                                        .clipShape(Circle())
                                }
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                        }

                        // Títulos
                        VStack(alignment: .leading, spacing: 4) {
                            Text(machine.name)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            Text(machine.type)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .padding()
                    }
                    .padding(.horizontal)

                    // Lista de variantes / videos
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Variantes")
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                        ForEach(machine.defaultVideos, id: \.id) { vid in
                            VideoRowCard(
                                video: vid,
                                onPlay: {
                                    // Mostrar diálogo antes de reproducir
                                    pendingVideoToPlay = vid
                                    withAnimation { showRegisterChoice = true }
                                },
                                onRegisterOnly: {
                                    // Registrar sin abrir player (si quisieras)
                                    ExerciseLogRepository.registerLogIfNeeded(video: vid, machine: machine) { _ in
                                        showTransientExerciseToast()
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(hex: "#F5F5F5").ignoresSafeArea())

            // Feedback Modal Flotante
            if showFeedbackDialog {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                FeedbackDialogView(
                    gymId: gym.id ?? "gym_001",
                    gymColorHex: gym.safeColor,
                    onDismiss: { dismissFeedback() },
                    onFeedbackSent: { dismissFeedback() }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(3)
            }

            // Toast general (feedback enviado)
            if showToast {
                VStack {
                    ToastView2(message: "¡Gracias por tus comentarios!")
                        .padding(.top, 50)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(4)
            }

            // Toast de registro de ejercicio
            if showExerciseToast {
                VStack {
                    Spacer()
                    ToastView2(message: "¡Ejercicio registrado en tu historial!")
                        .padding(.bottom, 60)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(5)
            }

            // Diálogo: Registrar y ver / Solo ver video
            if showRegisterChoice {
                Color.black.opacity(0.45).ignoresSafeArea()
                    .zIndex(10)

                RegisterChoiceDialog(
                    title: "¿Registrar ejercicio?",
                    message: "Elige si deseas registrar el ejercicio y ver el video de \(machine.name) o solo ver el video",
                    primaryTitle: "Registrar y ver",
                    secondaryTitle: "Solo ver video",
                    accentHex: gym.safeColor,
                    onPrimary: {
                        guard let video = pendingVideoToPlay else { return }
                        // Primero registramos
                        ExerciseLogRepository.registerLogIfNeeded(video: video, machine: machine) { _ in
                            showTransientExerciseToast()
                        }
                        // Luego abrimos player
                        openPlayer(video)
                    },
                    onSecondary: {
                        if let video = pendingVideoToPlay {
                            openPlayer(video)
                        }
                    },
                    onDismiss: {
                        withAnimation { showRegisterChoice = false }
                        pendingVideoToPlay = nil
                    }
                )
                .zIndex(11)
            }
        }
        .preferredColorScheme(.light)
        // Sheet con la descripción (se abre desde el botón info)
        .sheet(isPresented: $showInfoSheet) {
            MachineDescriptionSheet(machine: machine, accentHex: gym.safeColor)
        }
        // Player
        .fullScreenCover(item: $selectedVideo) { video in
            let dismissPlayer = {
                selectedVideo = nil
                if shouldShowFeedback2(feedbackFlags) {
                    showFeedbackDialog = true
                }
            }
            if (video.segments ?? []).isEmpty {
                VideoPlayerView(video: video) {
                    dismissPlayer()
                }
            } else {
                SegmentedVideoPlayerView(
                    video: video,
                    gymColor: Color(hex: gym.safeColor),
                    onDismiss: { dismissPlayer() },
                    onAllSegmentsFinished: {
                        if shouldShowFeedback2(feedbackFlags) {
                            showFeedbackDialog = true
                        }
                    }
                )
            }
        }
        // Mantiene tu lógica de aparición del feedback
        .task(id: "\(hasWatchedAllVideos)-\(feedbackFlags.first?.isShowFeedback == true)") {
            if shouldShowFeedback2(feedbackFlags) {
                showFeedbackDialog = true
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if shouldShowFeedback2(feedbackFlags) {
                    showFeedbackDialog = true
                }
            }
        }
    }

    // MARK: - Helpers

    private func openPlayer(_ video: Video) {
        withAnimation {
            showRegisterChoice = false
        }
        pendingVideoToPlay = nil
        selectedVideo = video
    }

    private func showTransientExerciseToast() {
        DispatchQueue.main.async {
            withAnimation { showExerciseToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { showExerciseToast = false }
            }
        }
    }

    private func dismissFeedback() {
        showFeedbackDialog = false
        guard feedbackFlags.isEmpty else { return }
        let flag = ShowFeedback(isShowFeedback: true)
        context.insert(flag)
        do {
            try context.save()
            withAnimation { showToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { showToast = false }
            }
        } catch {
            print("⚠️ Error al guardar ShowFeedback: \(error)")
        }
    }
}

// MARK: - Dialogo custom “Registrar y ver / Solo ver video”

private struct RegisterChoiceDialog: View {
    let title: String
    let message: String
    let primaryTitle: String
    let secondaryTitle: String
    let accentHex: String
    let onPrimary: () -> Void
    let onSecondary: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                // “tarjeta” centrada
                VStack(spacing: 18) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: accentHex))
                        .padding(.top, 12)

                    Text(title)
                        .font(.title3.bold())
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button(action: onPrimary) {
                        HStack {
                            Image(systemName: "play.fill")
                                .font(.headline)
                            Text(primaryTitle)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: accentHex))
                        .cornerRadius(14)
                    }

                    Button(action: onSecondary) {
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.headline)
                            Text(secondaryTitle)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 10)

                Button("Cancelar") { onDismiss() }
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Card de Video (diseño similar al adjunto)

private struct VideoRowCard: View {
    let video: Video
    let onPlay: () -> Void
    let onRegisterOnly: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Miniatura con botón de play
            ZStack {
                AsyncImage(url: URL(string: video.cover)) { img in
                    img.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 90, height: 120)
                        .clipped()
                        .cornerRadius(12)
                } placeholder: {
                    Color.gray.opacity(0.1)
                        .frame(width: 90, height: 120)
                        .cornerRadius(12)
                }
                
                // Capa oscura encima de la miniatura
                Color.black.opacity(0.35)
                    .frame(width: 90, height: 120)
                    .cornerRadius(12)

                Button(action: onPlay) {
                    Image(systemName: "play.fill")
                        .foregroundColor(Color.white.opacity(0.9))
                        .padding(8)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.accentColor, lineWidth: 2) // borde amarillo
                        )
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                // “Categoría” principal si la tienes (toma el de mayor peso si aplica)
                if let main = video.musclesWorked.sorted(by: { $0.value.weight > $1.value.weight }).first?.key {
                    Text(main)
                        .font(.caption.bold())
                        .foregroundColor(.black.opacity(0.7))
                }

                Text(video.title)
                    .font(.headline)
                    .foregroundColor(.black)

                // Chips de músculos secundarios (hasta 2 para evitar ruido)
                HStack(spacing: 8) {
                    ForEach(video.musclesWorked.sorted(by: { $0.value.weight > $1.value.weight }).prefix(2), id: \.key) { key, _ in
                        Text(key)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.05))
                            .foregroundColor(.black.opacity(0.8))
                            .cornerRadius(10)
                    }
                }

                // Botón registrar pequeño (opcional)
                Button(action: onRegisterOnly) {
                    HStack(spacing: 6) {
                        Text("Registrar")
                            .fontWeight(.bold)
                        Image(systemName: "list.bullet.rectangle.portrait")
                    }
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .cornerRadius(14)
                }
                .padding(.top, 4)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
}

// MARK: - Sheet con la descripción

private struct MachineDescriptionSheet: View {
    let machine: Machine
    let accentHex: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(machine.name)
                        .font(.title2.bold())
                    Text(machine.description)
                        .font(.body)
                        .foregroundColor(.black.opacity(0.8))
                }
                .padding()
            }
            .navigationTitle("Información")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(Color(hex: accentHex))
                }
            }
        }
    }
}

// MARK: - Utilidades y componentes que ya usabas

struct ToastView2: View {
    let message: String
    var body: some View {
        Text(message)
            .font(.body)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.8))
            .cornerRadius(8)
            .shadow(radius: 4)
            .transition(.opacity.combined(with: .move(edge: .top)))
            .zIndex(1)
    }
}

private extension MachineScreenContent2 {
    func shouldShowFeedback2(_ flags: [ShowFeedback]) -> Bool {
        hasWatchedAllVideos && flags.first?.isShowFeedback != true
    }
}

// MARK: - Extensiones auxiliares

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct MachineScreenContent_Previews2: PreviewProvider {
    static var previews: some View {
        let machine = Machine(
            id: "gym_001",
            name: "LEG PRESS",
            type: "Tren inferior",
            description: "Ideal para trabajar los cuádriceps y glúteos.",
            imageUrl: "",
            defaultVideos: [
                Video(
                    title: "Prensa de Pierna",
                    urlVideo: "https://www.youtube.com/watch?v=example",
                    cover: "https://example.com/cover.jpg",
                    musclesWorked: [
                        "Cuádriceps": Muscle(weight: 50, icon: "https://smartgym.b-cdn.net/icons/cuadriceps.svg"),
                        "Glúteos": Muscle(weight: 25, icon: "https://smartgym.b-cdn.net/icons/gluteos.svg"),
                        "Isquiotibiales": Muscle(weight: 25, icon: "https://smartgym.b-cdn.net/icons/isquiotibiales.svg")
                    ],
                    segments: []
                )
            ]
        )

        let gym = Gym(
            address: "Calle Falsa 123",
            color: "#FDD835",
            name: "InnovaFit Gym",
            owner: "Juan Pérez",
            phone: "123456789",
            isActive: true
        )

        MachineScreenContent2(machine: machine, gym: gym)
    }
}

struct JustifiedText: UIViewRepresentable {
    var text: String

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .justified
        label.font = .systemFont(ofSize: 18)
        label.text = text
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.text = text
    }
}

