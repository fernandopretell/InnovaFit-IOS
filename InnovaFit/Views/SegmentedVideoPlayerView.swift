import SwiftUI
import AVKit

struct SegmentedVideoPlayerView: View {
    let url: URL
    let segments: [Segment]
    let gymColor: Color
    let onDismiss: () -> Void
    let onAllSegmentsFinished: () -> Void

    @State private var player = AVPlayer()
    @State private var currentSegmentIndex = 0
    @State private var isShowingControls = false
    @State private var userSawAllSegments = false

    var body: some View {
        ZStack {
            VideoPlayer(player: player)
                .ignoresSafeArea()
                .onAppear {
                    player.replaceCurrentItem(with: AVPlayerItem(url: url))
                    playCurrentSegment()
                    addPeriodicTimeObserver()
                }

            // Logo superior
            VStack {
                HStack {
                    Spacer()
                    Image("AppLogo1")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 40)
                        .foregroundColor(gymColor)
                    Spacer()
                }
                .padding()
                Spacer()
            }

            // Overlay con controles
            if isShowingControls {
                VStack {
                    Spacer()
                    HStack(spacing: 30) {
                        if currentSegmentIndex > 0 {
                            ControlButton(icon: "arrow.left") {
                                currentSegmentIndex -= 1
                                playCurrentSegment()
                            }
                        }
                        ControlButton(icon: "gobackward") {
                            playCurrentSegment()
                        }
                        if currentSegmentIndex < segments.count - 1 {
                            ControlButton(icon: "arrow.right") {
                                currentSegmentIndex += 1
                                playCurrentSegment()
                            }
                        }
                    }
                    .padding(.bottom, 120)
                }
            }

            // Parte inferior con pasos y tip
            VStack {
                Spacer()
                VStack(spacing: 12) {
                    SegmentStepperView(
                        total: segments.count,
                        currentIndex: currentSegmentIndex,
                        color: gymColor
                    )
                    Text(segments[currentSegmentIndex].tip)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                }
                .padding()
                .background(Color.black.opacity(0.7))
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
    }

    func playCurrentSegment() {
        let segment = segments[currentSegmentIndex]
        player.seek(to: CMTime(seconds: segment.start, preferredTimescale: 600))
        player.play()
    }

    func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.3, preferredTimescale: 600)
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            let currentTime = time.seconds
            let segment = segments[currentSegmentIndex]
            if currentTime >= segment.end {
                player.pause()
                isShowingControls = true

                if currentSegmentIndex == segments.count - 1 {
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

struct SegmentStepperView: View {
    let total: Int
    let currentIndex: Int
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<total, id: \..self) { index in
                Circle()
                    .fill(index <= currentIndex ? color : Color.gray)
                    .frame(width: index == currentIndex ? 16 : 10, height: index == currentIndex ? 16 : 10)
            }
        }
    }
}
