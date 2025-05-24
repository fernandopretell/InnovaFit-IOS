import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let video: Video

    var body: some View {
        NavigationView {
            VStack {
                if let url = URL(string: video.urlVideo) {
                    VideoPlayer(player: AVPlayer(url: url))
                        .aspectRatio(16/9, contentMode: .fit)
                        .cornerRadius(12)
                        .padding()
                } else {
                    Text("URL de video inválida")
                        .foregroundColor(.red)
                }

                List {
                    Section(header: Text("Músculos trabajados")) {
                        let sortedMuscles = video.musclesWorked.sorted { $0.value.weight > $1.value.weight }

                        ForEach(sortedMuscles, id: \.key) { key, muscle in
                            HStack {
                                AsyncImage(url: URL(string: muscle.icon)) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 50, height: 50)
                                } placeholder: {
                                    ProgressView()
                                        .frame(width: 50, height: 50)
                                }

                                Text("\(key) (\(muscle.weight)%)")
                                    .font(.body)
                            }
                        }
                    }

                }
            }
            .navigationTitle(video.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
