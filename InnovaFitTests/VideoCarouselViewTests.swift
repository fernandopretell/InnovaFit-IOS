import XCTest
import ViewInspector
@testable import InnovaFit

extension VideoCarouselView: Inspectable {}

final class VideoCarouselViewTests: XCTestCase {
    func testOnVideoChangedTriggeredWhenScrollUpdates() throws {
        let videos = PreviewFactory.sampleMachine.defaultVideos
        var received: Video?
        var sut = VideoCarouselView(videos: videos, gymColor: "#FFFFFF", onVideoChanged: { video in
            received = video
        })

        let expAppear = sut.inspection.inspect { view in
            XCTAssertEqual(try view.actualView().scrollPosition, videos.count)
            try view.actualView().scrollPosition = videos.count + 1
            sut.inspection.notice.send(1)
        }

        let expChange = sut.inspection.inspect(after: 0.1) { _ in
            XCTAssertEqual(received, videos[1])
        }

        ViewHosting.host(view: sut)
        wait(for: [expAppear, expChange], timeout: 1.0)
        ViewHosting.expel()
    }
}
