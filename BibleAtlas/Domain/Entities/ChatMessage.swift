import Foundation

enum ChatRole: String, Codable {
    case user
    case assistant
}

struct ChatMessage: Codable, Hashable {
    let role: ChatRole
    let content: String
}
