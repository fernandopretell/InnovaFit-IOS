import UIKit
import Vision
import CoreImage

extension UIImage {
    func removingBackground() async -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .balanced
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            guard let maskBuffer = request.results?.first?.pixelBuffer else { return nil }
            let maskImage = CIImage(cvPixelBuffer: maskBuffer)
            let original = CIImage(cgImage: cgImage)
            let result = original.applyingFilter("CIBlendWithMask", parameters: [kCIInputMaskImageKey: maskImage])
            let context = CIContext()
            guard let cgResult = context.createCGImage(result, from: original.extent) else { return nil }
            return UIImage(cgImage: cgResult)
        } catch {
            return nil
        }
    }
}
