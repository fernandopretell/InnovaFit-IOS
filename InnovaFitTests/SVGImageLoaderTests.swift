import XCTest
@testable import InnovaFit

final class SVGImageLoaderTests: XCTestCase {
    func testLoadSVGTransformsAndStoresImage() async throws {
        let loader = SVGImageLoader()
        
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "test", withExtension: "svg") else {
            XCTFail("❌ No se encontró el archivo test.svg en el bundle de pruebas")
            return
        }
        
        let muscle = MuscleWithName(_id: "1", name: "Test", muscle: Muscle(weight: 50, icon: url.absoluteString))
        loader.loadSVGs(muscles: [muscle], gymColorHex: "#123456")
        
        let expectation = XCTestExpectation(description: "Image loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 5)
        
        XCTAssertNotNil(loader.images["Test"], "La imagen SVG no fue cargada correctamente")
    }
    
    func testSVGTransformAddsFillOpacity() throws {
        let loader = SVGImageLoader()
        let rawSVG = """
            <svg viewBox=\"0 0 100 100\" xmlns=\"http://www.w3.org/2000/svg\">
                <path d=\"M50 15 L90 85 H10 Z\" fill=\"#ff004f\"/>
            </svg>
            """
        let transformed = loader.transformSVG(rawSVG, color: "#123456", opacity: "0.77")
        
        XCTAssertTrue(transformed.contains("fill=\"#123456\""), "Debe reemplazar el color original")
        XCTAssertTrue(transformed.contains("fill-opacity=\"0.77\""), "Debe aplicar fill-opacity")
    }
    
    func testSVGTransformOverridesExistingFillOpacity() throws {
        let loader = SVGImageLoader()
        let rawSVG = """
            <svg viewBox=\"0 0 100 100\" xmlns=\"http://www.w3.org/2000/svg\">
                <path d=\"M50 15 L90 85 H10 Z\" fill=\"#ff004f\" fill-opacity=\"0.22\"/>
            </svg>
            """
        let transformed = loader.transformSVG(rawSVG, color: "#123456", opacity: "0.88")
        
        XCTAssertTrue(transformed.contains("fill=\"#123456\""), "Debe reemplazar el color original")
        XCTAssertTrue(transformed.contains("fill-opacity=\"0.88\""), "Debe sobrescribir fill-opacity existente")
        XCTAssertFalse(transformed.contains("fill-opacity=\"0.22\""), "No debe quedar la opacidad antigua")
    }
    
    func testSVGTransformNoMatchReturnsOriginal() throws {
        let loader = SVGImageLoader()
        let rawSVG = """
            <svg viewBox=\"0 0 100 100\" xmlns=\"http://www.w3.org/2000/svg\">
                <circle cx=\"50\" cy=\"50\" r=\"40\" fill=\"#000000\"/>
            </svg>
            """
        let transformed = loader.transformSVG(rawSVG, color: "#123456", opacity: "0.50")
        
        XCTAssertEqual(transformed, rawSVG, "Si no hay fill=#ff004f, el SVG debe mantenerse igual")
    }
}

#if DEBUG
extension SVGImageLoader {
    func transformSVG(_ raw: String, color: String, opacity: String) -> String {
        var stage1Svg = raw
        if let fillRegex = try? NSRegularExpression(pattern: "fill\\s*=\\s*\"#ff004f\"", options: .caseInsensitive) {
            let fillRange = NSRange(location: 0, length: stage1Svg.utf16.count)
            stage1Svg = fillRegex.stringByReplacingMatches(in: stage1Svg, options: [], range: fillRange, withTemplate: "fill=\"\(color)\"")
        }

        let pathElementRegex = try! NSRegularExpression(pattern: "<path\\b(?:[^>]*?fill=\\\"\(color)\\\"[^>]*?)>", options: [.caseInsensitive, .dotMatchesLineSeparators])
        let fullSvgNsRange = NSRange(location: 0, length: stage1Svg.utf16.count)
        var finalSvgString = ""
        var currentIndex = stage1Svg.startIndex

        pathElementRegex.enumerateMatches(in: stage1Svg, options: [], range: fullSvgNsRange) { (match, _, _) in
            guard let match = match, let matchRange = Range(match.range, in: stage1Svg) else { return }
            finalSvgString.append(String(stage1Svg[currentIndex..<matchRange.lowerBound]))

            var tag = String(stage1Svg[matchRange])
            if tag.contains("fill-opacity") {
                tag = tag.replacingOccurrences(of: #"fill-opacity=\"[^\"]*\""#, with: "fill-opacity=\"\(opacity)\"", options: .regularExpression)
            } else {
                let insertAt = tag.lastIndex(of: ">").map { tag.index(before: $0) } ?? tag.endIndex
                tag.insert(contentsOf: " fill-opacity=\"\(opacity)\"", at: insertAt)
            }

            finalSvgString.append(tag)
            currentIndex = matchRange.upperBound
        }

        if currentIndex < stage1Svg.endIndex {
            finalSvgString.append(String(stage1Svg[currentIndex...]))
        }

        return finalSvgString
    }
}
#endif
