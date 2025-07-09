import SwiftUI
import _SwiftData_SwiftUI
import SDWebImageSwiftUI

struct MachineScreenContent: View {
    let machine: Machine
    let gym: Gym
    
    @Query private var feedbackFlags: [ShowFeedback]
    @AppStorage("hasWatchedAllVideos") var hasWatchedAllVideos: Bool = false
    @Environment(\.modelContext) private var context
    @State private var showFeedbackDialog = false
    
    @State private var showToast = false
    @State private var selectedVideo: Video?
    @StateObject private var svgLoader = SVGImageLoader()

    
    init(machine: Machine, gym: Gym) {
        self.machine = machine
        self.gym = gym
        _selectedVideo = State(initialValue: machine.defaultVideos.first)
    }    
    
    var body: some View {
            ZStack {
                ScrollView {
                    VStack(spacing: 0) {
                        header
                        machineHeader
                        VideoCarouselView(
                            videos: machine.defaultVideos,
                            gymColor: gym.safeColor,
                            onVideoDismissed: { _ in handleVideoDismiss() },
                            onVideoChanged: { video in
                                print("🎞️ onVideoChanged -> \(video.title)")
                                video.musclesWorked.forEach { key, value in
                                    print("   - \(key): \(value.icon)")
                                }
                                selectedVideo = video
                            }
                        )
                        .onChange(of: selectedVideo) { oldValue, newVideo in
                            let loaderCopy = svgLoader
                            if let video = newVideo {
                                print("📹 MachineScreenContent - selectedVideo cambiado: \(video.title)")
                                video.musclesWorked.forEach { key, value in
                                    print("   - \(key): \(value.icon)")
                                }
                                loaderCopy.loadSVGs(
                                    muscles: video.musclesWorked.map { (name, muscle) in
                                        MuscleWithName(_id: name, name: name, muscle: muscle)
                                    },
                                    gymColorHex: gym.safeColor
                                )
                            } else {
                                print("📹 MachineScreenContent - selectedVideo es nil")
                            }
                        }

                        muscleTitle

                        MuscleListView(
                            musclesWorked: selectedVideo?.musclesWorked ?? [:],
                            gymColor: Color(hex: gym.safeColor),
                            loader: svgLoader,
                            videoId: selectedVideo?.id ?? ""
                        )
                    }
                    .onAppear {
                        if selectedVideo == nil {
                            selectedVideo = machine.defaultVideos.first
                        }

                        if let video = selectedVideo {
                            print("🆗 selectedVideo inicial: \(video.title)")
                            video.musclesWorked.forEach { key, value in
                                print("   - \(key): \(value.icon)")
                            }
                            svgLoader.loadSVGs(
                                muscles: video.musclesWorked.map { (name, muscle) in
                                    MuscleWithName(_id: name, name: name, muscle: muscle)
                                },
                                gymColorHex: gym.safeColor
                            )
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if shouldShowFeedback(feedbackFlags) {
                                showFeedbackDialog = true
                            }
                        }
                        print("hasWatchedAllVideos:", hasWatchedAllVideos)
                        print("feedbackFlags count:", feedbackFlags.count)
                    }
                    .sheet(isPresented: $showFeedbackDialog) {
                        FeedbackDialogView(
                            gymId: gym.id ?? "gym_001",
                            gymColorHex: gym.safeColor,
                            onDismiss: {
                                dismissFeedback()
                            },
                            onFeedbackSent: {
                                dismissFeedback()
                            }
                        )
                    }
                    .task(id: "\(hasWatchedAllVideos)-\(feedbackFlags.first?.isShowFeedback == true)") {
                        print("🔁 Task triggered with hasWatchedAllVideos: \(hasWatchedAllVideos), feedbackFlags: \(feedbackFlags)")

                        if shouldShowFeedback(feedbackFlags) {
                            showFeedbackDialog = true
                        }
                    }
                }

                if showToast {
                    VStack {
                        ToastView(message: "¡Gracias por tus comentarios!")
                            .padding(.top, 50) // Ajusta según tu layout y safe area
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
                }
            }
            .background(Color.white)
            .ignoresSafeArea(edges: .bottom)
            .navigationBarBackButtonHidden(true)
        }

    private var header: some View {
        ZStack(alignment: .center) {
            Color.black
                .clipShape(RoundedBottomShape(radius: 30))
                .frame(height: 55)
            
            Image("AppLogo1")
                .resizable()
                .scaledToFit()
                .frame(height: 25)
            
        }
        .background(Color(hex: gym.safeColor))
    }

    private var machineHeader: some View {
        VStack(spacing: 0) {
            Text(machine.name.uppercased())
                .font(.system(size: 30, weight: .heavy))
                .foregroundColor(Color.black)

            Text("Con esta máquina puedes trabajar")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.black)
        }
        .padding(.top, 16)
        .frame(maxWidth: .infinity)
        .background(Color(hex: gym.safeColor))
    }

    private var muscleTitle: some View {
        VStack(spacing: 0) {
            Text("Realizando este ejercicio")
                .font(.system(size: 22, weight: .heavy))
                .foregroundColor(Color.black)

            Text("Estarás trabajando los siguientes músculos...")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.black)
        }
    }
    
    func handleVideoDismiss() {
        print("↩️ Video dismiss detectado. hasWatchedAllVideos: \(hasWatchedAllVideos), flags: \(feedbackFlags)")
        
        if shouldShowFeedback(feedbackFlags) {
            showFeedbackDialog = true
        }
    }
    
    private func shouldShowFeedback(_ flags: [ShowFeedback]) -> Bool {
        return hasWatchedAllVideos && flags.first?.isShowFeedback != true
    }
    
    func dismissFeedback() {
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
            
            // Mostrar toast al guardar correctamente
            withAnimation {
                showToast = true
            }
            
            // Ocultar toast automáticamente tras 2.5 segundos
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

struct RoundedBottomShape: Shape {
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

struct ToastView: View {
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


struct MachineScreenContent_Previews: PreviewProvider {
    static var previews: some View {
        let machine = Machine(
            id: "gym_001",
            name: "LEG PRESS",
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

        MachineScreenContent(machine: machine, gym: gym)
    }
}

