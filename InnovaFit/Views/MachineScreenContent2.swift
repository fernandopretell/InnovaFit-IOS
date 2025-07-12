import SwiftUI
import _SwiftData_SwiftUI
import SDWebImageSwiftUI

struct MachineScreenContent2: View {
    let machine: Machine
    let gym: Gym

    @Environment(\.dismiss) private var dismiss
    @State private var selectedVideo: Video?

    @Query private var feedbackFlags: [ShowFeedback]
    @AppStorage("hasWatchedAllVideos") var hasWatchedAllVideos: Bool = false
    @Environment(\.modelContext) private var context
    @State private var showFeedbackDialog = false
    @State private var showToast = false
    @State private var showLogDialog = false
    @State private var videoToLog: Video?

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    
                    // Imagen principal con overlay y título
                    ZStack(alignment: .bottomLeading) {
                        AsyncImage(url: URL(string: machine.imageUrl)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 240)
                                .clipped()
                                .cornerRadius(12)
                        } placeholder: {
                            Color.gray.opacity(0.1)
                                .frame(height: 240)
                                .cornerRadius(12)
                        }
                        
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.8), .clear]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .cornerRadius(12)
                        .frame(height: 120)
                        
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(machine.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(machine.type)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                    
                    // Descripción
                    VStack(alignment: .leading, spacing: 8) {
                        Text(machine.description)
                            .font(.body)
                            .foregroundColor(.black)
                            .lineLimit(nil)
                    }
                    .padding(.horizontal)
                    
                    // Lista de videos sugeridos
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(machine.defaultVideos, id: \.id) { video in
                            VideoRowView(video: video) {
                                selectedVideo = video
                            }
                        }
                    }
                }
                .padding(.vertical)
            }

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
                .zIndex(1)
            }

            // Toast
            if showToast {
                VStack {
                    ToastView2(message: "¡Gracias por tus comentarios!")
                        .padding(.top, 50)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .preferredColorScheme(.light)
        .fullScreenCover(item: $selectedVideo) { video in
            if (video.segments ?? []).isEmpty {
                VideoPlayerView(video: video) {
                    videoToLog = video
                    selectedVideo = nil
                    if shouldShowFeedback2(feedbackFlags) {
                        showFeedbackDialog = true
                    }
                    showLogDialog = true
                }
            } else {
                SegmentedVideoPlayerView(
                    video: video,
                    gymColor: Color(hex: gym.safeColor),
                    onDismiss: {
                        videoToLog = video
                        selectedVideo = nil
                        if shouldShowFeedback2(feedbackFlags) {
                            showFeedbackDialog = true
                        }
                        showLogDialog = true
                    },
                    onAllSegmentsFinished: {
                        if shouldShowFeedback2(feedbackFlags) {
                            showFeedbackDialog = true
                        }
                    }
                )
            }
        }
        .alert(
            "¿Deseas agregar este ejercicio a tu historial?",
            isPresented: $showLogDialog
        ) {
            Button("Agregar") {
                if let video = videoToLog {
                    ExerciseLogRepository.registerLogIfNeeded(
                        video: video,
                        machine: machine
                    ) { result in
                        switch result {
                        case .success(let created):
                            print("✅ Log creado: \(created)")
                        case .failure(let error):
                            print("⚠️ Error al crear log: \(error)")
                        }
                    }
                }
            }
            Button("Cancelar", role: .cancel) {}
        }
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

    private func dismissFeedback() {
        showFeedbackDialog = false

        guard feedbackFlags.isEmpty else {
            print("ℹ️ Feedback ya registrado previamente.")
            return
        }

        let flag = ShowFeedback(isShowFeedback: true)
        context.insert(flag)

        do {
            try context.save()
            print("✅ Feedback marcado como mostrado en el dispositivo.")

            withAnimation {
                showToast = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    showToast = false
                }
            }
        } catch {
            print("⚠️ Error al guardar ShowFeedback: \(error)")
        }
    }
}


struct VideoRowView: View {
    let video: Video
    let onTap: () -> Void

    var body: some View {
        VStack {
            HStack(alignment: .top, spacing: 12) {
                ZStack(alignment: .center) {
                    AsyncImage(url: URL(string: video.cover)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 80)
                            .clipped()
                            .cornerRadius(8)
                    } placeholder: {
                        Color.gray.opacity(0.1)
                            .frame(width: 100, height: 80)
                            .cornerRadius(8)
                    }

                    // Capa blur
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.05)) // 👈 controla la intensidad del blur
                            .blur(radius: 2)
                            .frame(width: 100, height: 80)


                    Image(systemName: "play.fill")
                        .foregroundColor(Color.accentColor.opacity(0.7))
                        .padding(6)
                        .background(Color.gray.opacity(0.7))
                        .clipShape(Circle())
                        .padding(6)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(video.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.textTitle)

                    ForEach(video.musclesWorked.sorted(by: { $0.value.weight > $1.value.weight }), id: \.key) { key, value in
                        HStack {
                            Text(key)
                                .font(.caption)
                                .foregroundColor(.textBody)

                            Spacer()

                            Text("\(value.weight)%")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.textTitle)
                        }
                    }
                }
                .frame(maxWidth: .infinity) // 👈 hace que los HStack se expandan completamente
                //Spacer()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        .padding(.horizontal, 16)
        .onTapGesture {
            onTap()
        }
    }
}


struct RoundedBottomShape2: Shape {
    var radius: CGFloat = 30

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - radius))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height - radius),
            control: CGPoint(x: rect.width / 2, y: rect.height + radius)
        )
        path.closeSubpath()

        return path
    }
}

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

    func dismissFeedback2() {
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

