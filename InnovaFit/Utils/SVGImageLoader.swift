import Foundation
import UIKit
import SVGKit
import SwiftUI


class SVGImageLoader: ObservableObject {
    @Published var images: [String: UIImage] = [:]
    /// Keeps references to the tasks loading each SVG so they can be cancelled
    private var tasks: [String: Task<Void, Never>] = [:]

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

        for muscle in muscles {
            guard let url = URL(string: muscle.muscle.icon) else {
                print("⚠️ URL inválida para \(muscle.name): \(muscle.muscle.icon)")
                continue
            }

            let normalizedOpacity = max(0.2, min(1.0, Double(muscle.muscle.weight) / maxWeight))
            let opacityString = String(format: "%.2f", normalizedOpacity)

            let task = Task.detached { [weak self] in
                guard let self = self else {
                    print("❗️ self es nil, abortando carga de SVG para \(muscle.name)")
                    return
                }

                do {
                    let svgText = try await self.fetchSVGText(from: url)
                    var stage1Svg = svgText
                    
                    // 1. Reemplazar el color base fill="#ff004f" (o el que sea) por gymColorHex
                    //    Asegúrate que "#ff004f" es el color correcto a reemplazar globalmente si esa es la intención.
                    let baseFillColorToReplace = "#ff004f" // Puedes hacerlo una constante o parámetro si varía
                    if let fillRegex = try? NSRegularExpression(pattern: "fill\\s*=\\s*\"\(baseFillColorToReplace)\"", options: .caseInsensitive) {
                        let fillRange = NSRange(location: 0, length: stage1Svg.utf16.count)
                        stage1Svg = fillRegex.stringByReplacingMatches(in: stage1Svg, options: [], range: fillRange, withTemplate: "fill=\"\(gymColorHex)\"")
                    }

                    // 2. Modificar/Añadir fill-opacity a los paths que AHORA tienen gymColorHex
                    var finalSvgString = ""
                    var currentIndex = stage1Svg.startIndex
                    
                    // Regex para encontrar etiquetas <path ... > que contienen el fill="gymColorHex"
                    // Usamos (.|\n|\r) en [^>]* para que pueda manejar saltos de línea dentro de la etiqueta path si los hubiera.
                    // Hacemos que [^>]* sea no codicioso (*?) para evitar que consuma más de una etiqueta si están juntas y malformadas.
                    _ = "<path\\b([^>]*)fill=\\\"\(gymColorHex)\\\"[^>]*?>"
                    // Nota: El patrón anterior es para etiquetas que terminan en ">". Para "/>" se necesitaría un patrón más complejo o un post-procesamiento.
                    // Un patrón más general pero más complejo de manejar podría ser: <path\b((?:.|\n|\r)*?)>
                    // Vamos a simplificar asumiendo que la estructura de path es relativamente estándar.
                    // Este regex encontrará la etiqueta path completa que contenga el fill correcto.
                    
                    // Regex mejorado para capturar toda la etiqueta <path ...> o <path ... />
                    let pathElementRegex = try NSRegularExpression(pattern: "<path\\b(?:[^>]*?fill=\\\"\(gymColorHex)\\\"[^>]*?)>", options: [.caseInsensitive, .dotMatchesLineSeparators])

                    let fullSvgNsRange = NSRange(location: 0, length: stage1Svg.utf16.count)

                    pathElementRegex.enumerateMatches(in: stage1Svg, options: [], range: fullSvgNsRange) { (match, _, stop) in
                        guard let match = match, let matchRangeInOriginalSvg = Range(match.range, in: stage1Svg) else { return }
                        
                        // Añadir la parte del SVG antes de esta coincidencia
                        finalSvgString.append(String(stage1Svg[currentIndex..<matchRangeInOriginalSvg.lowerBound]))
                        
                        let pathTagString = String(stage1Svg[matchRangeInOriginalSvg])
                        var modifiedPathTagString = pathTagString
                        
                        // Buscar si fill-opacity ya existe en esta etiqueta path
                        let opacityAttributePattern = "fill-opacity\\s*=\\s*\\\"[^\\\"]*\\\""
                        let opacityRegex = try? NSRegularExpression(pattern: opacityAttributePattern, options: .caseInsensitive)
                        
                        if let opacityRegex = opacityRegex,
                           let existingOpacityAttrMatch = opacityRegex.firstMatch(in: modifiedPathTagString, options: [], range: NSRange(location: 0, length: modifiedPathTagString.utf16.count)),
                           let rangeToReplace = Range(existingOpacityAttrMatch.range, in: modifiedPathTagString) {
                            // fill-opacity existe, reemplazar su valor
                            modifiedPathTagString.replaceSubrange(rangeToReplace, with: "fill-opacity=\"\(opacityString)\"")
                        } else {
                            // fill-opacity no existe, añadirlo.
                            // Intentar añadirlo antes del cierre '>' o '/>'
                            if let lastChar = modifiedPathTagString.last {
                                var insertionPoint: String.Index
                                if lastChar == ">" {
                                    let secondLastCharIndex = modifiedPathTagString.index(before: modifiedPathTagString.endIndex)
                                    if secondLastCharIndex > modifiedPathTagString.startIndex && modifiedPathTagString[modifiedPathTagString.index(before: secondLastCharIndex)] == "/" { // Termina en "/>"
                                        insertionPoint = modifiedPathTagString.index(before: secondLastCharIndex) // Antes de "/"
                                    } else { // Termina en ">"
                                        insertionPoint = modifiedPathTagString.index(before: modifiedPathTagString.endIndex) // Antes de ">"
                                    }
                                    modifiedPathTagString.insert(contentsOf: " fill-opacity=\"\(opacityString)\"", at: insertionPoint)
                                } else {
                                    // Etiqueta path malformada o no termina en '>', se añade al final (menos ideal)
                                    print("⚠️ Etiqueta path no termina en '>' para \(muscle.name): \(pathTagString.prefix(100))")
                                    modifiedPathTagString.append(" fill-opacity=\"\(opacityString)\"")
                                }
                            } else {
                                 print("⚠️ Etiqueta path vacía o extraña para \(muscle.name): \(pathTagString)")
                            }
                        }
                        
                        finalSvgString.append(modifiedPathTagString)
                        currentIndex = matchRangeInOriginalSvg.upperBound
                    }
                    
                    // Añadir la parte restante del SVG después de la última coincidencia
                    if currentIndex < stage1Svg.endIndex {
                        finalSvgString.append(String(stage1Svg[currentIndex...]))
                    }
                    
                    // Si no hubo ninguna coincidencia de 'path' con 'gymColorHex', finalSvgString podría estar vacío
                    // o solo contener las partes iniciales. En ese caso, el SVG modificado es stage1Svg.
                    if pathElementRegex.numberOfMatches(in: stage1Svg, options: [], range: fullSvgNsRange) == 0 {
                        finalSvgString = stage1Svg
                    }

                    print("SVG modificado para \(muscle.name) (\(url.lastPathComponent)):\n\(finalSvgString.prefix(300))") // Imprime solo una parte para no llenar la consola
                    
                    guard let data = finalSvgString.data(using: .utf8),
                          let svgImage = SVGKImage(data: data) else { // Asumiendo SVGKImage es la clase correcta
                        print("❌ Error creando SVGKImage para \(muscle.name) (\(url.lastPathComponent))")
                        // Si quieres ver el SVG que falló:
                        // print("SVG que falló: \(finalSvgString)")
                        return
                    }
                    
                    DispatchQueue.main.async(execute: {
                        self.images[muscle.name] = svgImage.uiImage // Asumiendo .uiImage es la propiedad correcta
                        print("✅ Imagen SVG cargada y procesada para \(muscle.name) (\(url.lastPathComponent))")
                    })
                    
                } catch {
                    print("❌ Error procesando SVG para \(muscle.name) (\(url.lastPathComponent)): \(error.localizedDescription)")
                }
            }
            tasks[muscle.name] = task
        } // Fin del bucle for
    } // Fin de la función

    /// Cancels any ongoing SVG loading tasks
    func cancelAllTasks() {
        for (name, task) in tasks {
            if !task.isCancelled {
                task.cancel()
                print("⛔️ Cancelled task for \(name)")
            }
        }
        tasks.removeAll()
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
