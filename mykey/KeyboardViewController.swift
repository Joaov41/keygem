//
//  KeyboardViewController.swift
//  Custom Keyboard Extension
//
//  NOTE: Requires GeminiProvider.swift + GeminiConfig in the same target.
//  Features Added:
//    • Debug panel with logs toggled by a "Debug" button.
//    • Forced dark mode (overrideUserInterfaceStyle = .dark).
//    • Globe button (Next Keyboard button) to switch back to the system keyboard.
//    • When the Custom button is pressed, the extension retrieves a custom prompt
//      (saved by the main app via an App Group) and uses it in the API call.
//  Retains your existing logic for rewriting, summarizing, etc.
//
import UIKit

class KeyboardViewController: UIInputViewController {

    // MARK: - LLM
    private lazy var geminiProvider: GeminiProvider = {
        let config = GeminiConfig(
            apiKey: "API KEY",  // Your API key
            modelName: "gemini-2.0-flash"
        )
        return GeminiProvider(config: config)
    }()

    // MARK: - Main UI Buttons
    private let proofreadButton    = makeButton(title: "Proofread")
    private let rewriteButton      = makeButton(title: "Rewrite")
    private let friendlyButton     = makeButton(title: "Friendly")
    private let professionalButton = makeButton(title: "Professional")
    private let conciseButton      = makeButton(title: "Concise")
    private let summaryButton      = makeButton(title: "Summary")
    private let keyPointsButton    = makeButton(title: "Key Points")
    private let customButton       = makeButton(title: "Custom")

    // MARK: - Debug Button
    private let debugButton = makeButton(title: "Debug")
    
    // MARK: - Next Keyboard (Globe) Button
    private let nextKeyboardButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "globe"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Title & Status
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "My Keyboard"
        lbl.font = UIFont.boldSystemFont(ofSize: 16)
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let statusLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = .systemBlue
        lbl.textAlignment = .center
        lbl.font = UIFont.systemFont(ofSize: 14)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // MARK: - Debug Panel
    private let debugPopupView: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.systemGray4.cgColor
        v.layer.cornerRadius = 10
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()

    private let debugTextView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.font = UIFont.systemFont(ofSize: 12)
        tv.backgroundColor = .systemBackground
        tv.textColor = .label
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let debugCloseButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Close Debug", for: .normal)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    /// Accumulated debug text to display in the debug panel
    private var debugLog: String = ""

    // MARK: - Result Pop-up for Summary/Key Points
    private let resultPopupView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.systemGray4.cgColor
        v.layer.cornerRadius = 10
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()

    private let resultTextView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.font = UIFont.systemFont(ofSize: 14)
        tv.backgroundColor = .secondarySystemBackground
        tv.textColor = .label
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let closeResultButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Close", for: .normal)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: - Custom Prompt Pop-up (Unused in this shared-prompt approach)
    private let customPopupView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 8
        v.layer.borderColor = UIColor.systemGray4.cgColor
        v.layer.borderWidth = 2
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()

    private let customTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter custom instruction"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    private let customCancelButton = makeButton(title: "Cancel")
    private let customApplyButton  = makeButton(title: "Apply")

    // MARK: - Stored snippet for custom mode
    private var pendingSnippet: String? = nil

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        view.backgroundColor = .black

        // Title & Status
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        // Main Stack for Buttons
        let row1 = UIStackView(arrangedSubviews: [proofreadButton, rewriteButton, friendlyButton, professionalButton])
        row1.axis = .horizontal
        row1.distribution = .fillEqually
        row1.spacing = 6

        let row2 = UIStackView(arrangedSubviews: [conciseButton, summaryButton, keyPointsButton, customButton])
        row2.axis = .horizontal
        row2.distribution = .fillEqually
        row2.spacing = 6

        let row3 = UIStackView(arrangedSubviews: [debugButton])
        row3.axis = .horizontal
        row3.distribution = .fillEqually
        row3.spacing = 6

        let stack = UIStackView(arrangedSubviews: [row1, row2, row3])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 6),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6)
        ])

        // Button Actions
        proofreadButton.addTarget(self, action: #selector(handleProofreadTap), for: .touchUpInside)
        rewriteButton.addTarget(self, action: #selector(handleRewriteTap), for: .touchUpInside)
        friendlyButton.addTarget(self, action: #selector(handleFriendlyTap), for: .touchUpInside)
        professionalButton.addTarget(self, action: #selector(handleProfessionalTap), for: .touchUpInside)
        conciseButton.addTarget(self, action: #selector(handleConciseTap), for: .touchUpInside)
        summaryButton.addTarget(self, action: #selector(handleSummaryTap), for: .touchUpInside)
        keyPointsButton.addTarget(self, action: #selector(handleKeyPointsTap), for: .touchUpInside)
        customButton.addTarget(self, action: #selector(handleCustomTap), for: .touchUpInside)
        debugButton.addTarget(self, action: #selector(toggleDebugPopup), for: .touchUpInside)

        // Next Keyboard (Globe) Button
        view.addSubview(nextKeyboardButton)
        NSLayoutConstraint.activate([
            nextKeyboardButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            nextKeyboardButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
        nextKeyboardButton.addTarget(self, action: #selector(handleNextKeyboardButton), for: .touchUpInside)

        // Debug Pop-up
        view.addSubview(debugPopupView)
        debugPopupView.addSubview(debugTextView)
        debugPopupView.addSubview(debugCloseButton)
        NSLayoutConstraint.activate([
            debugPopupView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            debugPopupView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            debugPopupView.widthAnchor.constraint(equalToConstant: 320),
            debugPopupView.heightAnchor.constraint(equalToConstant: 220),
            debugTextView.topAnchor.constraint(equalTo: debugPopupView.topAnchor, constant: 8),
            debugTextView.leadingAnchor.constraint(equalTo: debugPopupView.leadingAnchor, constant: 8),
            debugTextView.trailingAnchor.constraint(equalTo: debugPopupView.trailingAnchor, constant: -8),
            debugTextView.bottomAnchor.constraint(equalTo: debugCloseButton.topAnchor, constant: -8),
            debugCloseButton.centerXAnchor.constraint(equalTo: debugPopupView.centerXAnchor),
            debugCloseButton.bottomAnchor.constraint(equalTo: debugPopupView.bottomAnchor, constant: -8)
        ])
        debugCloseButton.addTarget(self, action: #selector(closeDebugPopup), for: .touchUpInside)

        // Result Pop-up
        view.addSubview(resultPopupView)
        resultPopupView.addSubview(resultTextView)
        resultPopupView.addSubview(closeResultButton)
        NSLayoutConstraint.activate([
            resultPopupView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resultPopupView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            resultPopupView.widthAnchor.constraint(equalToConstant: 280),
            resultPopupView.heightAnchor.constraint(equalToConstant: 180),
            resultTextView.topAnchor.constraint(equalTo: resultPopupView.topAnchor, constant: 8),
            resultTextView.leadingAnchor.constraint(equalTo: resultPopupView.leadingAnchor, constant: 8),
            resultTextView.trailingAnchor.constraint(equalTo: resultPopupView.trailingAnchor, constant: -8),
            resultTextView.bottomAnchor.constraint(equalTo: closeResultButton.topAnchor, constant: -8),
            closeResultButton.centerXAnchor.constraint(equalTo: resultPopupView.centerXAnchor),
            closeResultButton.bottomAnchor.constraint(equalTo: resultPopupView.bottomAnchor, constant: -8)
        ])
        closeResultButton.addTarget(self, action: #selector(closeResultPopup), for: .touchUpInside)

        // (Optional) Custom Pop-up – not used when sharing the prompt
        view.addSubview(customPopupView)
        customPopupView.addSubview(customTextField)
        customPopupView.addSubview(customCancelButton)
        customPopupView.addSubview(customApplyButton)
        NSLayoutConstraint.activate([
            customPopupView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            customPopupView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            customPopupView.widthAnchor.constraint(equalToConstant: 260),
            customPopupView.heightAnchor.constraint(equalToConstant: 140),
            customTextField.topAnchor.constraint(equalTo: customPopupView.topAnchor, constant: 8),
            customTextField.leadingAnchor.constraint(equalTo: customPopupView.leadingAnchor, constant: 8),
            customTextField.trailingAnchor.constraint(equalTo: customPopupView.trailingAnchor, constant: -8),
            customCancelButton.leadingAnchor.constraint(equalTo: customPopupView.leadingAnchor, constant: 16),
            customCancelButton.bottomAnchor.constraint(equalTo: customPopupView.bottomAnchor, constant: -12),
            customApplyButton.trailingAnchor.constraint(equalTo: customPopupView.trailingAnchor, constant: -16),
            customApplyButton.bottomAnchor.constraint(equalTo: customPopupView.bottomAnchor, constant: -12)
        ])
        customCancelButton.addTarget(self, action: #selector(dismissCustomPopup), for: .touchUpInside)
        // We are not using customApplyButton as a selector because we retrieve the prompt from shared storage.
    }

    // MARK: - Make Button Helper
    private static func makeButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        btn.backgroundColor = .darkGray
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 8
        btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }

    // MARK: - Next Keyboard Action
    @objc private func handleNextKeyboardButton() {
        self.advanceToNextInputMode()
    }

    // MARK: - Debug Logging
    private func log(_ message: String) {
        let timeString = Date().description(with: .current)
        let line = "[\(timeString)] \(message)\n"
        debugLog.append(line)
        if !debugPopupView.isHidden {
            debugTextView.text = debugLog
            let bottomRange = NSMakeRange(debugTextView.text.count - 1, 1)
            debugTextView.scrollRangeToVisible(bottomRange)
        }
    }

    @objc private func toggleDebugPopup() {
        debugPopupView.isHidden.toggle()
        if !debugPopupView.isHidden {
            debugTextView.text = debugLog
        }
    }

    @objc private func closeDebugPopup() {
        debugPopupView.isHidden = true
    }

    // MARK: - Rewriting Functions
    @objc private func handleProofreadTap() {
        let prompt = """
        You are a grammar proofreading assistant. Correct grammar, spelling, punctuation, keeping style. Output only corrected text.
        """
        rewriteInline(prompt: prompt, mode: "Proofread")
    }

    @objc private func handleRewriteTap() {
        let prompt = """
        Rewrite to improve phrasing, grammar, readability. Output only the rewritten text.
        """
        rewriteInline(prompt: prompt, mode: "Rewrite")
    }

    @objc private func handleFriendlyTap() {
        let prompt = """
        Rewrite text to be more friendly. Keep meaning and structure. Output only new text.
        """
        rewriteInline(prompt: prompt, mode: "Friendly")
    }

    @objc private func handleProfessionalTap() {
        let prompt = """
        Rewrite text to be more formal/professional. Keep meaning. Output only new text.
        """
        rewriteInline(prompt: prompt, mode: "Professional")
    }

    @objc private func handleConciseTap() {
        let prompt = """
        Rewrite text to be concise and clear. Keep original meaning/tone. Output only the rewritten text.
        """
        rewriteInline(prompt: prompt, mode: "Concise")
    }

    // MARK: - Summary & Key Points
    @objc private func handleSummaryTap() {
        let prompt = """
        Summarize the text succinctly. Output only the summary.
        """
        showResultPopup(prompt: prompt, mode: "Summary")
    }

    @objc private func handleKeyPointsTap() {
        let prompt = """
        Extract the key points from the text. Output only those key points.
        """
        showResultPopup(prompt: prompt, mode: "KeyPoints")
    }

    // MARK: - Custom Prompt Handling (Shared Custom Prompt)
    // This function retrieves the custom prompt saved by your main app via the App Group.
    @objc private func handleCustomTap() {
        // Capture the snippet from the host app.
        if let snippet = captureSelectedOrBeforeCursor() {
            pendingSnippet = snippet
            log("handleCustomTap => snippet:\n\(snippet)")
        } else {
            pendingSnippet = nil
            log("handleCustomTap => snippet is nil/empty.")
        }
        statusLabel.text = "Custom Prompt"
        
        // Retrieve the custom prompt from shared UserDefaults.
        if let customPrompt = UserDefaults(suiteName: "group.com.red.keygem")?.string(forKey: "customPrompt"), !customPrompt.isEmpty {
            // Call the helper function directly—no selector needed.
            applyCustomInstruction(with: customPrompt)
        } else {
            statusLabel.text = "No custom prompt set."
            log("No custom prompt found in shared storage.")
        }
    }

    @objc private func dismissCustomPopup() {
        customPopupView.isHidden = true
    }

    // MARK: - Apply Custom Instruction Using Shared Prompt
    // This function is called directly (not via a button target) so no @objc is required.
    private func applyCustomInstruction(with instruction: String) {
        guard let snippet = pendingSnippet, !snippet.isEmpty else {
            statusLabel.text = "No text to apply custom prompt."
            log("applyCustomInstruction => no pending snippet.")
            return
        }
        UIPasteboard.general.string = snippet
        log("applyCustomInstruction => instruction:\n\(instruction)\nsnippet:\n\(snippet)")
        statusLabel.text = "Processing custom..."
        Task {
            do {
                let prompt = """
                Apply the user's changes to the text. Output only modified text.

                Instruction:
                \(instruction)

                Text:
                \(snippet)
                """
                log("Custom => sending prompt:\n\(prompt)")
                let result = try await geminiProvider.processText(userPrompt: prompt)
                let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    for _ in 0..<snippet.count {
                        textDocumentProxy.deleteBackward()
                    }
                    textDocumentProxy.insertText(trimmed)
                    UIPasteboard.general.string = trimmed
                    statusLabel.text = "Done!"
                    log("applyCustomInstruction => result:\n\(trimmed)")
                } else {
                    statusLabel.text = "Empty result from LLM."
                    log("applyCustomInstruction => got empty result.")
                }
            } catch {
                statusLabel.text = "Error: \(error.localizedDescription)"
                log("applyCustomInstruction => Error: \(error)")
            }
        }
    }

    // MARK: - Inline Rewriting
    private func rewriteInline(prompt: String, mode: String) {
        guard let snippet = captureSelectedOrBeforeCursor() else {
            statusLabel.text = "No text found."
            log("[\(mode)] => snippet is nil/empty.")
            return
        }
        UIPasteboard.general.string = snippet
        statusLabel.text = "Processing..."
        log("[\(mode)] => snippet captured:\n\(snippet)\n")
        log("[\(mode)] => sending prompt:\n\(prompt)\n---")
        Task {
            do {
                let finalPrompt = prompt + "\n\n" + snippet
                let result = try await geminiProvider.processText(userPrompt: finalPrompt)
                let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
                log("[\(mode)] => LLM response:\n\(trimmed)")
                if trimmed.isEmpty {
                    statusLabel.text = "Empty result."
                    log("[\(mode)] => empty result => text preserved.")
                } else {
                    for _ in 0..<snippet.count {
                        textDocumentProxy.deleteBackward()
                    }
                    textDocumentProxy.insertText(trimmed)
                    statusLabel.text = "Done!"
                }
            } catch {
                statusLabel.text = "Error: \(error.localizedDescription)"
                log("[\(mode)] => Error: \(error)")
            }
        }
    }

    // MARK: - Summaries Pop-up
    private func showResultPopup(prompt: String, mode: String) {
        guard let snippet = captureSelectedOrBeforeCursor() else {
            statusLabel.text = "No text found."
            log("[\(mode)] => snippet is nil/empty.")
            return
        }
        UIPasteboard.general.string = snippet
        statusLabel.text = "Processing..."
        log("[\(mode)] => snippet captured:\n\(snippet)\n")
        log("[\(mode)] => sending prompt:\n\(prompt)\n---")
        Task {
            do {
                let finalPrompt = prompt + "\n\n" + snippet
                let result = try await geminiProvider.processText(userPrompt: finalPrompt)
                let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
                resultTextView.text = trimmed
                resultPopupView.isHidden = false
                statusLabel.text = "Done!"
                log("[\(mode)] => LLM response:\n\(trimmed)")
            } catch {
                statusLabel.text = "Error: \(error.localizedDescription)"
                log("[\(mode)] => Error: \(error)")
            }
        }
    }

    @objc private func closeResultPopup() {
        resultPopupView.isHidden = true
    }

    // MARK: - Capture Snippet
    private func captureSelectedOrBeforeCursor() -> String? {
        guard let proxy = textDocumentProxy as? UITextDocumentProxy else { return nil }
        var snippet: String? = nil
        if #available(iOS 16.0, *) {
            if let sel = proxy.selectedText, !sel.isEmpty { snippet = sel }
        }
        if snippet == nil || snippet?.isEmpty == true {
            snippet = proxy.documentContextBeforeInput
        }
        snippet = snippet?.trimmingCharacters(in: .whitespacesAndNewlines)
        return snippet?.isEmpty == false ? snippet : nil
    }
}
