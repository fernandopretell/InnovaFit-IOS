import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let video: Video
    var onDismiss: () -> Void

    @State private var queuePlayer: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let url = URL(string: video.urlVideo) {
                VideoPlayer(player: queuePlayer)
                    .edgesIgnoringSafeArea(.all)
                    .onAppear {
                        let asset = AVURLAsset(url: url)
                        let item = AVPlayerItem(asset: asset)
                        let player = AVQueuePlayer()
                        self.looper = AVPlayerLooper(player: player, templateItem: item)
                        self.queuePlayer = player
                        player.play()
                    }
            } else {
                Color.black
                Text("URL de video inválida")
                    .foregroundColor(.white)
                    .bold()
            }

            // Botón de cierre
            Button(action: {
                onDismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.white)
                    .shadow(radius: 4)
                    .padding()
            }
        }
    }
}



