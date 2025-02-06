import SwiftUI

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var geminiProvider: GeminiProvider
    @Published var customInstruction: String = ""
    @Published var selectedText: String = ""
    @Published var isProcessing: Bool = false
    @Published var showOnboarding: Bool = false
    @Published var showSettings: Bool = false
    @Published var showAbout: Bool = false
    @Published var showCustomInput: Bool = false
    @Published var showChat: Bool = false
    @Published var showImageProcessing: Bool = false

    @Published var activeResponse: ResponseData? = nil
    @Published var sharedContent: String? = nil
    @Published var lastUpdateTimestamp: TimeInterval = 0

    @Published var selectedImage: UIImage? = nil
    @Published var imageProcessingResult: String? = nil

    private var contentUpdateTimer: Timer? // Timer for periodic checks

    private init() {
        let apiKey = UserDefaults.standard.string(forKey: "gemini_api_key")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let modelName = UserDefaults.standard.string(forKey: "gemini_model") ?? GeminiModel.flash.rawValue

        if apiKey.isEmpty {
            print("Warning: Gemini API key is not configured.")
        }

        let config = GeminiConfig(apiKey: apiKey, modelName: modelName)
        self.geminiProvider = GeminiProvider(config: config)

        // Setup notification observers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleContentUpdate),
            name: UIScene.didActivateNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleContentUpdate),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleContentUpdate),
            name: Notification.Name("com.red.tools.sharedContentUpdated"),
            object: nil
        )

        // Start the timer when AppState is initialized
        startContentUpdateTimer()

        // Initial content check
        checkForContentUpdates()
    }

    deinit {
        // Invalidate the timer and remove observers
        stopContentUpdateTimer()
        NotificationCenter.default.removeObserver(self)
    }

    func saveConfig(apiKey: String, model: GeminiModel) {
        UserDefaults.standard.setValue(apiKey, forKey: "gemini_api_key")
        UserDefaults.standard.setValue(model.rawValue, forKey: "gemini_model")

        let config = GeminiConfig(apiKey: apiKey, modelName: model.rawValue)
        geminiProvider = GeminiProvider(config: config)
    }

    // Start the content update timer
    private func startContentUpdateTimer() {
        contentUpdateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkForContentUpdates()
        }
    }

    // Stop the content update timer
    private func stopContentUpdateTimer() {
        contentUpdateTimer?.invalidate()
        contentUpdateTimer = nil
    }

    @objc private func handleContentUpdate() {
        checkForContentUpdates()
    }

    private func checkForContentUpdates() {
        if let userDefaults = UserDefaults(suiteName: "group.red.tools"),
           let lastUpdate = userDefaults.double(forKey: "lastUpdateTimestamp") as TimeInterval?,
           lastUpdate > lastUpdateTimestamp {
            lastUpdateTimestamp = lastUpdate
            DispatchQueue.main.async {
                self.sharedContent = userDefaults.string(forKey: "sharedContent")
                print("Content updated: \(self.sharedContent ?? "nil")")
            }
        }
    }

    func updateSharedContent() {
        checkForContentUpdates()
    }

    func processSelectedImage(withPrompt prompt: String) async throws -> String {
        guard let image = selectedImage else {
            throw NSError(domain: "ImageProcessing", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "No image selected"])
        }

        isProcessing = true
        defer { isProcessing = false }

        return try await geminiProvider.processImageAndText(image: image, prompt: prompt)
    }
}
