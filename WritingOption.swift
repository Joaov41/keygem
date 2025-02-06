import SwiftUI

enum WritingOption: String, CaseIterable, Identifiable {
    case custom = "Custom"
    case proofread = "Proofread"
    case rewrite = "Rewrite"
    case friendly = "Friendly"
    case professional = "Professional"
    case concise = "Concise"
    case summary = "Summary"
    case keyPoints = "Key Points"
    case table = "Table"

    var id: String { rawValue }

    var systemPrompt: String {
        switch self {
        case .custom:
            return """
            You are a writing assistant. Your sole task is to apply the user's specified changes...
            """
        case .proofread:
            return """
            You are a grammar proofreading assistant...
            """
        case .rewrite:
            return """
            You are a rewriting assistant...
            """
        case .friendly:
            return """
            You are a rewriting assistant (friendly tone)...
            """
        case .professional:
            return """
            You are a rewriting assistant (formal tone)...
            """
        case .concise:
            return """
            You are a rewriting assistant (concise text)...
            """
        case .summary:
            return """
            You are a summarization assistant...
            """
        case .keyPoints:
            return """
            You are an assistant for extracting key points...
            """
        case .table:
            return """
            You are a text-to-table assistant...
            """
        }
    }

    var icon: String {
        switch self {
        case .custom: return "pencil"
        case .proofread: return "magnifyingglass"
        case .rewrite: return "arrow.triangle.2.circlepath"
        case .friendly: return "face.smiling"
        case .professional: return "briefcase"
        case .concise: return "scissors"
        case .summary: return "doc.text"
        case .keyPoints: return "list.bullet"
        case .table: return "tablecells"
        }
    }

    var isCustomOption: Bool {
        self == .custom
    }
}
