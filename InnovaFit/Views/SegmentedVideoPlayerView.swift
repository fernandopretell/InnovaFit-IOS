import SwiftUI
import _SwiftData_SwiftUI
import AVKit

struct SegmentedVideoPlayerView: View {
    let video: Video
    let gymColor: Color
    let onDismiss: () -> Void
    let onAllSegmentsFinished: () -> Void

    @State private var player = AVPlayer()
    @State private var currentSegmentIndex = 0
    @State private var isShowingControls = false
    @State private var userSawAllSegments = false
    
    @Environment(\.dismiss) private var dismiss
    
    @Environment(\.modelContext) private var context
    @Query private var feedbackFlags: [ShowFeedback]
    @State private var showFeedbackDialog = false
    
    @AppStorage("hasWatchedAllVideos") var hasWatchedAllVideos: Bool = false
    
    @State private var watchedSegmentIndices: Set<Int> = []

    var body: some View {
        ZStack {
            CustomVideoPlayer(videoURL: URL(string: video.urlVideo)!) { player in
                self.player = player
                playCurrentSegment()
                addPeriodicTimeObserver()
            }
            .ignoresSafeArea()
            
            // Logo superior
            VStack {
                HStack {
                    Spacer()
                    Image("AppLogo1")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 30) // equivalente a fillMaxHeight con padding vertical
                        .foregroundColor(gymColor) // tint del color del gimnasio
                    Spacer()
                    
                    Button(action: {
                                dismiss()
                            }) {
                                Text("×")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 10)
                            }
                }
                .frame(height: 70)
                .background(Color.black.opacity(0.8))
                
                Spacer()
            }
            .zIndex(10)
            
            // Overlay con controles
            if isShowingControls {
                ZStack {
                    Color.black.opacity(0.5) // Fondo semitransparente opcional
                        .ignoresSafeArea()
                    
                    HStack(spacing: 35) {
                        // Botón Anterior
                        if currentSegmentIndex > 0 {
                            Button(action: {
                                withAnimation {
                                    currentSegmentIndex -= 1
                                    playCurrentSegment()
                                    isShowingControls = false
                                }
                            }) {
                                Image("icon_prev") // 🔁 PNG externo
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                            }
                        }
                        
                        // Botón Repetir
                        Button(action: {
                            withAnimation {
                                playCurrentSegment()
                                isShowingControls = false
                            }
                        }) {
                            Image("icon_retry")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                        }
                        
                        // Botón Siguiente
                        if currentSegmentIndex < video.safeSegments.count - 1 {
                            Button(action: {
                                withAnimation {
                                    currentSegmentIndex += 1
                                    playCurrentSegment()
                                    isShowingControls = false
                                }
                            }) {
                                Image("icon_next")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                            }
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                .animation(.easeInOut(duration: 0.3), value: isShowingControls)
            }
            
            
            // Parte inferior con pasos y tip
            VStack {
                Spacer()
                HStack(alignment: .center) {
                    SegmentStepperView(
                        total: video.safeSegments.count,
                        currentIndex: currentSegmentIndex,
                        color: gymColor
                    )
                    .frame(width: 40, height: 100) // 🔧 Limita el alto aquí
                    
                    Text(video.safeSegments[currentSegmentIndex].tip)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity, alignment: .leading) // 🔧 importante
                        .animation(.easeInOut(duration: 0.3), value: currentSegmentIndex)
                }
                .frame(height: 100)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black.opacity(0.8))
            }.ignoresSafeArea(edges: .bottom)
            
        }
        .onDisappear {
            if userSawAllSegments {
                hasWatchedAllVideos = true
                print("🎯 hasWatchedAllVideos actualizado a true")
            }
        }
        .onTapGesture {
            if !isShowingControls {
                isShowingControls = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    isShowingControls = false
                }
            }
        }
        .onChange(of: hasWatchedAllVideos) {
            print("📦 hasWatchedAllVideos cambió a: \(hasWatchedAllVideos)")
        }
        
    }
    
    func markSegmentWatched(index: Int) {
        watchedSegmentIndices.insert(index)

        print("📺 Segmento \(index) visto. Total vistos: \(watchedSegmentIndices.count)/\(video.safeSegments.count)")

        if watchedSegmentIndices.count == video.safeSegments.count {
            print("🎯 Todos los segmentos vistos — hasWatchedAllVideos marcado")
            hasWatchedAllVideos = true
        }
    }
        
    private func checkIfFinishedAllSegments() {
        if currentSegmentIndex == video.safeSegments.count - 1 {
            userSawAllSegments = true
        }
    }
    
    func shouldShowFeedback() -> Bool {
        // Si no hay ningún registro, lo mostramos
        feedbackFlags.first?.isShowFeedback != true
    }

    func markFeedbackAsShown() {
        if let record = feedbackFlags.first {
            record.isShowFeedback = true
        } else {
            let newRecord = ShowFeedback(isShowFeedback: true)
            context.insert(newRecord)
        }
        try? context.save()
    }


    func playCurrentSegment() {
        let segment = video.safeSegments[currentSegmentIndex]
        let startInSeconds = Double(segment.start) / 1000.0
        player.seek(to: CMTime(seconds: startInSeconds, preferredTimescale: 600))
        player.play()
    }

    func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.3, preferredTimescale: 600)
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            let currentTime = time.seconds
            let segment = video.safeSegments[currentSegmentIndex]
            let endInSeconds = Double(segment.end) / 1000.0
            if currentTime >= endInSeconds {
                player.pause()
                isShowingControls = true
                
                markSegmentWatched(index: currentSegmentIndex) // ✅ Agregado

                if currentSegmentIndex == video.safeSegments.count - 1 {
                    userSawAllSegments = true
                    onAllSegmentsFinished()
                }
            }

        }
    }
}

struct ControlButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
        }
    }
}

struct CustomVideoPlayer: UIViewControllerRepresentable {
    let videoURL: URL
    let onReady: ((AVPlayer) -> Void)?  // permite que llames playCurrentSegment() y observer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVPlayer(url: videoURL)
        
        DispatchQueue.main.async {
            onReady?(player) // ahora es seguro
        }
        
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspect
        
        // ⚠️ Aquí desactivamos la interacción del view del reproductor
        controller.view.isUserInteractionEnabled = false
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // no hace falta actualizar
    }
}



struct SegmentStepperView: View {
    let total: Int
    let currentIndex: Int
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 16
            let smallDiameter: CGFloat = 14
            let largeDiameter: CGFloat = 28
            let circleHeights = (0..<total).map { $0 == currentIndex ? largeDiameter : smallDiameter }
            let totalHeight = circleHeights.reduce(0, +) + spacing * CGFloat(total - 1)

            ZStack(alignment: .top) {
                // Línea del centro del primer al último círculo
                Rectangle()
                    .fill(color)
                    .frame(width: 2, height: totalHeight)
                    .position(x: geometry.size.width / 2, y: totalHeight / 2)

                VStack(spacing: spacing) {
                    ForEach(0..<total, id: \.self) { index in
                        ZStack {
                            Circle()
                                .fill(color)
                                .frame(width: index == currentIndex ? largeDiameter : smallDiameter,
                                       height: index == currentIndex ? largeDiameter : smallDiameter)

                            if index == currentIndex {
                                Text("\(index + 1)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.black)
                            }
                        }
                    }
                }
            }
            .frame(width: geometry.size.width, height: totalHeight)
        }
        .frame(width: 40) // Contenedor externo
    }
}

struct SegmentedVideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        SegmentedVideoPlayerView(
            video: Video(
                title: "Demo Video",
                urlVideo: "https://smartgym.b-cdn.net/videos/leg_press/leg_press_estandar.mp4",
                cover: "cover.png",
                musclesWorked: [:],
                segments: [
                    Segment(start: 0, end: 5000, tip: "Apoya los pies firmemente y alinea las rodillas."),
                    Segment(start: 5000, end: 11000, tip: "Mantén la espalda pegada al asiento en todo momento."),
                    Segment(start: 11000, end: 16000, tip: "Controla el movimiento sin bloquear las rodillas.")
                ]
            ),
            gymColor: Color(hex: "#FDD835"),
            onDismiss: {},
            onAllSegmentsFinished: {}
        )
    }
}
