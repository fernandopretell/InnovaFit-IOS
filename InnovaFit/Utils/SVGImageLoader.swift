import Foundation
import UIKit
@preconcurrency import SVGKit
import SwiftUI


class SVGImageLoader: ObservableObject {
    
    @Published var images: [String: UIImage] = [:]
    private var currentTasks: [String: Task<Void, Never>] = [:]


    /// Fetches the SVG text from the given url using `URLSession` so that
    /// the request contains a default user agent. Some of the CDN endpoints
    /// used in the project return a `403` response when using
    /// `String(contentsOf:)` which internally relies on a simple data task
    /// without these headers. Using `URLSession` avoids that restriction.
    private func fetchSVGText(from url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let text = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        return text
    }

    func loadSVGs(muscles: [MuscleWithName], gymColorHex: String) {
        let maxWeight = muscles.map { Double($0.muscle.weight) }.max() ?? 1.0

        currentTasks.values.forEach { $0.cancel() }
        currentTasks.removeAll()

        for muscle in muscles {
            guard let url = URL(string: muscle.muscle.icon) else {
                print("⚠️ URL inválida para \(muscle.name): \(muscle.muscle.icon)")
                continue
            }

            let normalizedOpacity = max(0.2, min(1.0, Double(muscle.muscle.weight) / maxWeight))
            let opacityString = String(format: "%.2f", normalizedOpacity)

            let task = Task { @MainActor in
                guard !Task.isCancelled else { return }

                do {
                    let svgText = try await fetchSVGText(from: url)
                    var stage1Svg = svgText

                    let baseFillColorToReplace = "#ff004f"
                    if let fillRegex = try? NSRegularExpression(pattern: "fill\\s*=\\s*\"\(baseFillColorToReplace)\"", options: .caseInsensitive) {
                        let fillRange = NSRange(location: 0, length: stage1Svg.utf16.count)
                        stage1Svg = fillRegex.stringByReplacingMatches(in: stage1Svg, options: [], range: fillRange, withTemplate: "fill=\"\(gymColorHex)\"")
                    }

                    var finalSvgString = ""
                    var currentIndex = stage1Svg.startIndex

                    let pathElementRegex = try NSRegularExpression(pattern: "<path\\b(?:[^>]*?fill=\\\"\(gymColorHex)\\\"[^>]*?)>", options: [.caseInsensitive, .dotMatchesLineSeparators])
                    let fullSvgNsRange = NSRange(location: 0, length: stage1Svg.utf16.count)

                    pathElementRegex.enumerateMatches(in: stage1Svg, options: [], range: fullSvgNsRange) { (match, _, _) in
                        guard let match = match, let matchRange = Range(match.range, in: stage1Svg) else { return }

                        finalSvgString.append(String(stage1Svg[currentIndex..<matchRange.lowerBound]))

                        var pathTagString = String(stage1Svg[matchRange])
                        let opacityPattern = "fill-opacity\\s*=\\s*\\\"[^\\\"]*\\\""
                        let opacityRegex = try? NSRegularExpression(pattern: opacityPattern, options: .caseInsensitive)

                        if let opacityRegex = opacityRegex,
                           let existing = opacityRegex.firstMatch(in: pathTagString, options: [], range: NSRange(location: 0, length: pathTagString.utf16.count)),
                           let range = Range(existing.range, in: pathTagString) {
                            pathTagString.replaceSubrange(range, with: "fill-opacity=\"\(opacityString)\"")
                        } else {
                            if pathTagString.hasSuffix("/>") {
                                let insertAt = pathTagString.index(pathTagString.endIndex, offsetBy: -2)
                                pathTagString.insert(contentsOf: " fill-opacity=\"\(opacityString)\"", at: insertAt)
                            } else if pathTagString.hasSuffix(">") {
                                let insertAt = pathTagString.index(before: pathTagString.endIndex)
                                pathTagString.insert(contentsOf: " fill-opacity=\"\(opacityString)\"", at: insertAt)
                            }
                        }

                        finalSvgString.append(pathTagString)
                        currentIndex = matchRange.upperBound
                    }

                    if currentIndex < stage1Svg.endIndex {
                        finalSvgString.append(String(stage1Svg[currentIndex...]))
                    }

                    if pathElementRegex.numberOfMatches(in: stage1Svg, options: [], range: fullSvgNsRange) == 0 {
                        finalSvgString = stage1Svg
                    }

                    guard let data = finalSvgString.data(using: .utf8),
                          let svgImage = SVGKImage(data: data) else {
                        print("❌ Error creando SVGKImage para \(muscle.name)")
                        return
                    }

                    self.images[muscle.name] = svgImage.uiImage
                    print("✅ Imagen SVG cargada para \(muscle.name)")
                } catch {
                    if !Task.isCancelled {
                        print("❌ Error cargando SVG para \(muscle.name): \(error)")
                    }
                }
            }

            currentTasks[muscle.name] = task
        }
    }
}

extension SVGKImage {
    func fillColor(replacing oldHex: String, with newColor: UIColor) {
        guard let layer = self.caLayerTree else { return }
        replaceFillColor(in: layer, oldHex: oldHex.lowercased(), newColor: newColor.cgColor)
    }

    private func replaceFillColor(in layer: CALayer, oldHex: String, newColor: CGColor) {
        if let shape = layer as? CAShapeLayer,
           let currentColor = shape.fillColor,
           UIColor(cgColor: currentColor).hexString.lowercased() == oldHex {
            shape.fillColor = newColor
        }

        layer.sublayers?.forEach {
            replaceFillColor(in: $0, oldHex: oldHex, newColor: newColor)
        }
    }
}

extension UIColor {
    var hexString: String {
        guard let components = cgColor.components else { return "#000000" }
        let r = Int((components[0] * 255).rounded())
        let g = Int((components[safe: 1] ?? components[0]) * 255)
        let b = Int((components[safe: 2] ?? components[0]) * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

extension Color {
    func toHex() -> String {
        // Convert SwiftUI.Color → UIColor
        let uiColor = UIColor(self)

        guard let components = uiColor.cgColor.components else { return "#FDD535" }

        let r = Int((components[safe: 0] ?? 0) * 255)
        let g = Int((components[safe: 1] ?? 0) * 255)
        let b = Int((components[safe: 2] ?? 0) * 255)

        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

extension Collection {
    public subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}


