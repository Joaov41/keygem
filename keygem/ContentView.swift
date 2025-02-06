import SwiftUI

struct ContentView: View {
    // State variables
    @State private var customPrompt: String = ""
    @State private var message: String = "Welcome to Keygem"
    @State private var isShowingAlert = false
    
    // Constants
    private let appGroupID = "group.com.red.keygem"
    
    var body: some View {
        VStack(spacing: 16) {
            // Title
            Text(message)
                .font(.title)
                .padding()
            
            // Instructions
            Text("To enable the keyboard:")
                .font(.headline)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("1. Open Settings")
                Text("2. Go to General → Keyboard → Keyboards")
                Text("3. Add New Keyboard")
                Text("4. Enable Keygem")
                Text("5. Allow Full Access")
            }
            .padding(.horizontal)
            
            Divider()
                .padding(.vertical)
            
            // Custom Prompt Section
            Text("Custom Prompt")
                .font(.headline)
            
            TextField("Enter your prompt here...", text: $customPrompt)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            // Save Button
            Button(action: saveCustomPrompt) {
                Text("Save Prompt")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .onAppear(perform: verifyAppGroupAccess)
        .alert("Prompt Saved", isPresented: $isShowingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your custom prompt has been saved and is ready to use in the keyboard.")
        }
    }
    
    // MARK: - Functions
    private func saveCustomPrompt() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else {
            message = "Error: Could not access shared storage"
            return
        }
        
        sharedDefaults.set(customPrompt, forKey: "customPrompt")
        sharedDefaults.synchronize()
        
        message = "Prompt saved successfully!"
        isShowingAlert = true
        
        // Debug print
        print("Saved prompt: \(customPrompt)")
    }
    
    private func verifyAppGroupAccess() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else {
            print("❌ Cannot access App Group")
            message = "Error: App Group access failed"
            return
        }
        
        let testValue = "test_\(Date())"
        sharedDefaults.set(testValue, forKey: "test_key")
        
        if let readValue = sharedDefaults.string(forKey: "test_key"),
           readValue == testValue {
            print("✅ App Group working correctly")
        } else {
            print("❌ App Group verification failed")
            message = "Error: App Group verification failed"
        }
    }
}

#Preview {
    ContentView()
}
