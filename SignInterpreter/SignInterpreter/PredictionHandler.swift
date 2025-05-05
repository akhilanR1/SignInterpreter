import Vision
import CoreML
import UIKit

class PredictionHandler {
    private var model: VNCoreMLModel?

    init() {
        do {
            let config = MLModelConfiguration()
            let aslModel = try ASLClassifier(configuration: config)
            self.model = try VNCoreMLModel(for: aslModel.model)
        } catch {
            print("Error loading model: \(error)")
        }
    }

    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage!
    }

    func predictImage(image: UIImage, completion: @escaping (String) -> Void) {
        guard let model = model else {
            print("Model not loaded")
            completion("Model not loaded")
            return
        }

        let resizedImage = resizeImage(image: image, targetSize: CGSize(width: 299, height: 299))

        guard let cgImage = resizedImage.cgImage else {
            print("Could not create CGImage from image")
            completion("Invalid image")
            return
        }

        let request = VNCoreMLRequest(model: model) { request, error in
            if let results = request.results as? [VNClassificationObservation],
               let topResult = results.first {
                let confidencePercent = Int(topResult.confidence * 100)
                let result = "\(topResult.identifier) (\(confidencePercent)%)"
                print("Prediction: \(result)")
                DispatchQueue.main.async {
                    completion(result)
                }
            } else {
                print("No results from captured photo")
                DispatchQueue.main.async {
                    completion("No prediction")
                }
            }
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
        } catch {
            print("Error performing prediction: \(error)")
            completion("Prediction error")
        }
    }
}
