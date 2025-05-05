import SwiftUI
import AVFoundation
import Vision

struct CameraView: UIViewRepresentable {
    @Binding var capturedImage: UIImage?

    func makeCoordinator() -> CameraCoordinator {
        return CameraCoordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        context.coordinator.startSession()
        context.coordinator.previewLayer.frame = view.bounds
        view.layer.addSublayer(context.coordinator.previewLayer)
        return view
    }


    func updateUIView(_ uiView: UIView, context: Context) {
    }

    
    class CameraCoordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        let session = AVCaptureSession()
        var previewLayer: AVCaptureVideoPreviewLayer!
        let predictor = PredictionHandler()
        var parent: CameraView

        init(parent: CameraView) {
            self.parent = parent
            super.init()

            session.sessionPreset = .photo

            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device) else { return }

            if session.canAddInput(input) {
                session.addInput(input)
            }

            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))

            if session.canAddOutput(output) {
                session.addOutput(output)
            }

            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
        }

        func startSession() {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }


        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                print("No pixel buffer")
                return
            }

            let ciImage = CIImage(cvPixelBuffer: imageBuffer)
            let context = CIContext()
            if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                let uiImage = UIImage(cgImage: cgImage)

                DispatchQueue.main.async {
                    self.parent.capturedImage = uiImage


                    self.predictor.predictImage(image: uiImage) { prediction in
                        NotificationCenter.default.post(name: .didReceivePrediction, object: prediction)
                    }
                }
            } else {
                print("Could not create CGImage from CIImage")
            }
        }
    }
}
