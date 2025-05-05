import SwiftUI
import Vision

struct ContentView: View {
    @State private var prediction: String = "Waiting for input..."
    @State private var sentence: String = ""
    @State private var lastAddedLetter: String = ""
    @State private var lastLetterTime: Date = Date()
    @State private var capturedImage: UIImage?

    var body: some View {
        ZStack(alignment: .bottom) {

            CameraView(capturedImage: $capturedImage)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 16) {
                
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                }


                Text("Prediction: \(prediction)")
                    .font(.title2)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(10)

                Text("Phrase: \(sentence)")
                    .font(.title)
                    .bold()
                    .padding(.bottom, 10)
                    .foregroundColor(.white)
            }
            .padding(.bottom, 40)
        }
        .onAppear {

            NotificationCenter.default.addObserver(forName: .didReceivePrediction, object: nil, queue: .main) { notification in
                if let newPrediction = notification.object as? String {
                    self.prediction = newPrediction

                    let letter = newPrediction.components(separatedBy: " ").first ?? ""
                    let now = Date()
                    let interval = now.timeIntervalSince(lastLetterTime)

                    if letter != lastAddedLetter && interval > 1.0 && letter.count == 1 {
                        sentence += letter
                        lastAddedLetter = letter
                        lastLetterTime = now
                    }
                }
            }
        }
    }
}
