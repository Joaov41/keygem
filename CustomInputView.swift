import SwiftUI

struct CustomInputView: View {
    @State private var customText: String = ""
    let onCancel: () -> Void
    let onResult: (String) -> Void

    // Minimal GeminiProvider
    private let geminiProvider = GeminiProvider(
        config: GeminiConfig(apiKey: "YOUR_API_KEY",
                             modelName: "gemini-2.0-flash")
    )

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Enter Custom Instruction")
                    .font(.headline)

                TextField("Describe your change...", text: $customText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onSubmit {
                        processCustomChange()
                    }
                    .submitLabel(.send)

                HStack {
                    Button("Cancel", action: onCancel)
                    Button("Apply") {
                        processCustomChange()
                    }
                    .disabled(customText.isEmpty)
                }

                Spacer()
            }
            .padding()
            .navigationBarTitle("Custom Instruction", displayMode: .inline)
        }
    }

    private func processCustomChange() {
        guard !customText.isEmpty else { return }

        Task {
            do {
                let prompt = """
                You are a writing assistant. Apply the user's custom changes:
                \(customText)

                Text:
                [Place text to modify here if needed]
                """

                let result = try await geminiProvider.processText(userPrompt: prompt)
                onResult(result)
            } catch {
                print("Error: \(error.localizedDescription)")
                onResult("Error applying custom instruction.")
            }
        }
    }
}
