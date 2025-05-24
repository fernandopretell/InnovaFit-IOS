import SwiftUI
import SDWebImageSwiftUI

struct VideoCarouselView: View {
    
    let videos: [Video]
    let gymColor: String
    
    @State private var currentIndex: Int = 0 // Start from the first real slide
    @State private var selectedVideo: Video? = nil
    private let slideWidth = UIScreen.main.bounds.width * 0.6
    private let slideSpacing: CGFloat = 25
    
    var loopedVideos: [Video] {
        guard let first = videos.first, let last = videos.last else { return [] }
        return [last] + videos + [first] // [último, reales..., primero]
    }
    
    var body: some View {
        
        ZStack(alignment: .center) {
            GeometryReader { geometry in
                    let totalHeight = geometry.size.height

                    VStack(spacing: 0) {
                        Color(hex: gymColor)
                            .frame(height: totalHeight * 0.3) // 30% del alto disponible

                        Color.black
                            .frame(height: totalHeight * 0.01) // 2%

                        Color.white
                            .frame(height: totalHeight * 0.69) // 68%
                    }
                    .edgesIgnoringSafeArea(.all) // opcional
            }
            .frame(maxWidth: .infinity)
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: slideSpacing) {
                        ForEach(videos.indices, id: \.self) { index in
                            ZStack {
                                WebImage(url: URL(string: videos[index].cover))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: slideWidth, height: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.black, lineWidth: 7)
                                    )
                                
                                Button {
                                    selectedVideo = videos[index]
                                } label: {                                    ZStack {
                                        // Play icono centrado
                                        ZStack {
                                            Image("icon_play")
                                                .resizable()
                                                .frame(width: 60, height: 60)
                                        }
                                        
                                        // Texto en parte inferior
                                        VStack {
                                            Spacer()
                                            
                                            Text(videos[index].title)
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(Color(hex: gymColor))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.black)
                                                .cornerRadius(12)
                                                .padding(.bottom, 16)
                                        }
                                    }
                                    .frame(width: slideWidth, height: 310)
                                }
                            }
                            .id(index)
                        }
                    }
                    .padding(.horizontal, (UIScreen.main.bounds.width - slideWidth) / 2)
                    .background(GeometryReader { geo in
                        Color.clear.preference(
                            key: ScrollOffsetKey.self,
                            value: geo.frame(in: .global).minX
                        )
                    })
                }
                .onPreferenceChange(ScrollOffsetKey.self) { offset in
                    // Cálculo del índice del slide visible
                    let totalSlideWidth = slideWidth + slideSpacing
                    let centerOffset = offset - (UIScreen.main.bounds.width - slideWidth) / 2
                    let newIndex = Int(round(-centerOffset / totalSlideWidth))
                    
                    if newIndex != currentIndex && newIndex >= 0 && newIndex < videos.count {
                        currentIndex = newIndex
                        withAnimation {
                            proxy.scrollTo(currentIndex, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(height: 348)
        .sheet(item: $selectedVideo) { video in
                    if (video.segments ?? []).isEmpty {
                        VideoPlayerView(video: video)
                    } else {
                        SegmentedVideoPlayerView(video: video)
                    }
                }
    }
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct VideoCarouselView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VideoCarouselView(
                videos: PreviewFactory.sampleMachine.defaultVideos,
                gymColor: PreviewFactory.sampleGym.color  ?? "#FDD835"
            )
        }
    }
}
