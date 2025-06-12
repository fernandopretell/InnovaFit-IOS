import SwiftUI
import SDWebImageSwiftUI

struct VideoCarouselView: View {

    let videos: [Video]
    let gymColor: String
    var onVideoDismissed: ((Video) -> Void)? = nil
    var onVideoChanged: ((Video) -> Void)? = nil

    internal let inspection = Inspection<Self>()

    @State private var scrollPosition: Int?
    @State private var itemsArray: [[Video]] = []
    @State private var selectedVideo: Video?
    
    private let animationDuration: CGFloat = 0.3
    private let animation: Animation = .default
    
    var body: some View {
        
        let screenWidth = UIScreen.main.bounds.width
        let cardWidth: CGFloat = 180
        let cardHeight: CGFloat = 220
        let containerHeight = cardHeight * 1.3
        let widthDifference = screenWidth - cardWidth
        
        ZStack(alignment: .top) {
            Color.clear.frame(height: cardHeight)
                .clipped()
            
            // FONDO DE COLORES
            VStack(spacing: 0) {
                Color(hex: gymColor)
                    .frame(height: containerHeight * 0.3)
                
                Color.black
                    .frame(height: containerHeight * 0.01)
                
                Color.white
                    .frame(height: containerHeight * 0.69)
            }
            .frame(height: containerHeight)
            
            let flatVideos: [Video] = itemsArray.flatMap { $0 }
            let itemCount = videos.count
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    
                    ForEach(flatVideos.indices, id: \.self) { index in
                        let video = flatVideos[index]
                        let isFocused = index == scrollPosition
                        
                        VideoCardView(
                            video: video,
                            isFocused: isFocused,
                            gymColor: gymColor,
                            pageWidth: cardWidth,
                            pageHeight: cardHeight,
                            onTap: {
                                selectedVideo = video
                            }
                        )
                        .padding(.horizontal, (widthDifference)/2)
                        .offset(x: (index == scrollPosition) ? 0 : (index < scrollPosition ?? flatVideos.count) ? widthDifference*0.75 : -widthDifference*0.75)
                    }
                }
                .scrollTargetLayout()
            }
            .frame(height: containerHeight)
            .scrollPosition(id: $scrollPosition, anchor: .center)
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .onAppear {
                self.itemsArray = [videos, videos, videos]
                scrollPosition = itemCount
            }
            .onChange(of: scrollPosition) { newScroll in
                guard let scroll = newScroll else { return }
                
                if scroll / itemCount == 0 && scroll % itemCount == itemCount - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                        itemsArray.removeLast()
                        itemsArray.insert(videos, at: 0)
                        scrollPosition = scroll + itemCount
                    }
                } else if scroll / itemCount == 2 && scroll % itemCount == 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                        itemsArray.removeFirst()
                        itemsArray.append(videos)
                        scrollPosition = scroll - itemCount
                    }
                }
                
                if flatVideos.indices.contains(scroll) {
                    onVideoChanged?(flatVideos[scroll])
                }
            }
        }
        .fullScreenCover(item: $selectedVideo, onDismiss: {
            onVideoDismissed?(selectedVideo!)
        }) { video in
            if (video.segments ?? []).isEmpty {
                VideoPlayerView(video: video)
            } else {
                SegmentedVideoPlayerView(
                    video: video,
                    gymColor: Color(hex: gymColor),
                    onDismiss: {
                        selectedVideo = nil
                    },
                    onAllSegmentsFinished: {
                        // Acciones opcionales
                    }
                )
            }
        }
        .onReceive(inspection.notice) { inspection.visit(self, $0) }
    }
}

struct VideoCardView: View {
    let video: Video
    let isFocused: Bool
    let gymColor: String
    let pageWidth: CGFloat
    let pageHeight: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            WebImage(url: URL(string: video.cover))
                .resizable()
                .scaledToFill()
                .frame(width: pageWidth, height: isFocused ? pageHeight * 1.2 : pageHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black, lineWidth: 7)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Play icono centrado con acción
            Button(action: {
                onTap()
            }) {
                ZStack {
                    Image("icon_play")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(Color(hex: gymColor))
                }
            }
            .buttonStyle(.plain) // ← evita efecto azul por defecto
            
            
            // Texto en parte inferior
            VStack {
                Spacer()
                
                Text(video.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: gymColor))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black)
                    .cornerRadius(12)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: pageWidth - 32) // ⬅️ deja 16pt a cada lado como margen visual
                    .padding(.bottom, 16)
            }
            .frame(width: pageWidth, height: isFocused ? pageHeight * 1.2 : pageHeight)
        }
    }
}

struct VideoCarouselView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VideoCarouselView(
                videos: PreviewFactory.sampleMachine.defaultVideos,
                gymColor: PreviewFactory.sampleGym.color  ?? "#FDD835",
                onVideoDismissed: {_ in },
                onVideoChanged: {_ in }
            )
        }
    }
}
