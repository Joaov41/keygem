import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Keygem app")
                .font(.largeTitle)
                .padding()

            Text("This is just a minimal container app. To use the Keygem keyboard, please go to Settings → General → Keyboard → Keyboards and enable it.")
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}
