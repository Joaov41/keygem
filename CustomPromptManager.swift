import Foundation

class CustomPromptManager {
    static let shared = CustomPromptManager()
    let appGroupIdentifier = "group.com.red.keygem"  // Use the same identifier you set up in Xcode

    // Save the custom prompt to shared UserDefaults
    func saveCustomPrompt(_ prompt: String) {
        UserDefaults(suiteName: appGroupIdentifier)?.set(prompt, forKey: "customPrompt")
    }
    
    // Retrieve the custom prompt from shared UserDefaults
    func getCustomPrompt() -> String? {
        return UserDefaults(suiteName: appGroupIdentifier)?.string(forKey: "customPrompt")
    }
}//
//  CustomPromptManager.swift
//  keygem
//
//  Created by john val on 2/1/25.
//

