import XCTest
@testable import InnovaFit

final class SVGImageLoaderTests: XCTestCase {
    func testLoadSVGTransformsAndStoresImage() async throws {
        let loader = SVGImageLoader()
        guard let url = Bundle.module.url(forResource: "test", withExtension: "svg", subdirectory: "Resources") else {
            XCTFail("Resource not found")
            return
        }
        let muscle = MuscleWithName(_id: "1", name: "Test", muscle: Muscle(weight: 50, icon: url.absoluteString))
        loader.loadSVGs(muscles: [muscle], gymColorHex: "#123456")

        let expectation = XCTestExpectation(description: "Image loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 5)

        XCTAssertNotNil(loader.images["Test"])
    }
}
