import UIKit
import Vision
import CoreImage

extension UIImage {
    func removingBackground() async -> UIImage? {
        print("[BG_REMOVAL] Inicio de removingBackground()")
        guard let cgImage = self.cgImage else {
            print("[BG_REMOVAL] ❌ No CGImage disponible")
            return nil
        }
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .balanced
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            print("[BG_REMOVAL] Ejecutando request de segmentación…")
            try handler.perform([request])

            guard
                let results = request.results,
                let maskBuffer = results.first?.pixelBuffer
            else {
                print("[BG_REMOVAL] ❌ No se obtuvo pixelBuffer del mask")
                return nil
            }
            print("[BG_REMOVAL] ✅ Mask buffer obtenido: tamaño \(CVPixelBufferGetWidth(maskBuffer))x\(CVPixelBufferGetHeight(maskBuffer))")

            // Convertir a CIImage
            let maskImage = CIImage(cvPixelBuffer: maskBuffer)
            let original = CIImage(cgImage: cgImage)

            // Aplicar máscara
            let blended = original.applyingFilter(
                "CIBlendWithMask",
                parameters: [kCIInputMaskImageKey: maskImage]
            )
            print("[BG_REMOVAL] Composición con máscara aplicada")

            // Crear CGImage de salida
            let context = CIContext()
            guard let cgResult = context.createCGImage(blended, from: original.extent) else {
                print("[BG_REMOVAL] ❌ No se pudo crear CGImage de resultado")
                return nil
            }
            print("[BG_REMOVAL] ✅ CGImage de resultado creado, devolviendo UIImage final")
            return UIImage(cgImage: cgResult, scale: self.scale, orientation: self.imageOrientation)
        } catch {
            print("[BG_REMOVAL] ❌ Error durante la petición Vision: \(error.localizedDescription)")
            return nil
        }
    }
}

