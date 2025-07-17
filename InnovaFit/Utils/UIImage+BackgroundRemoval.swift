import UIKit
import Vision
import CoreImage

private extension CIImage {
    /// Escala la máscara para que tenga la misma altura que otra imagen, manteniendo proporción.
    func resizeToSameHeight(as other: CIImage) -> CIImage {
        let sizeSelf = extent.size
        let sizeOther = other.extent.size
        let scaleX = sizeOther.width  / sizeSelf.width
        let scaleY = sizeOther.height / sizeSelf.height
        return transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
    }
}

extension UIImage {
    func removingBackground() async -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }

        // 1. Configurar la petición
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .accurate
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        // NO usamos imageCropAndScaleOption

        // 2. Ejecutar Vision
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("[BG_REMOVAL] Error Vision: \(error)")
            return nil
        }
 
        // 3. Obtener maskBuffer
        guard
            let obs = request.results?.first as? VNPixelBufferObservation
        else {
            print("[BG_REMOVAL] No hay VNPixelBufferObservation")
            return nil
        }
        let maskBuffer = obs.pixelBuffer

        // 4. Transformar a CIImage y escalar+centrar
        let originalCI = CIImage(cgImage: cgImage)
        let maskSmallCI = CIImage(cvPixelBuffer: maskBuffer)

        // Escala la máscara a la misma altura que la original
        let maskResizedCI = maskSmallCI.resizeToSameHeight(as: originalCI)

        // Centra horizontalmente
        let dx = -(maskResizedCI.extent.width - originalCI.extent.width) / 2
        let maskCenteredCI = maskResizedCI.transformed(by: CGAffineTransform(translationX: dx, y: 0))

        // 5. Crear fondo transparente
        let transparentBG = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0))
            .cropped(to: originalCI.extent)

        // 6. Mezclar con la máscara
        guard
            let blend = CIFilter(name: "CIBlendWithMask", parameters: [
                kCIInputImageKey:          originalCI,
                kCIInputBackgroundImageKey: transparentBG,
                kCIInputMaskImageKey:      maskCenteredCI
            ])?.outputImage
        else {
            print("[BG_REMOVAL] Falló CIBlendWithMask")
            return nil
        }

        // 7. Renderizar y devolver UIImage
        let context = CIContext()
        guard let cgResult = context.createCGImage(blend, from: originalCI.extent) else {
            print("[BG_REMOVAL] No pudo crear CGImage final")
            return nil
        }
        return UIImage(cgImage: cgResult, scale: scale, orientation: imageOrientation)
    }
}



