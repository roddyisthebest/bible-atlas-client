import Foundation

enum ChatBubbleKind: Hashable {
    case user
    case assistant(placeIdMap: [String: [String]], recommendedQuestions: [String])
    case pending(label: String)
    case error(String)
}

struct ChatBubble: Identifiable, Hashable {
    let id: UUID
    let kind: ChatBubbleKind
    let text: String

    init(id: UUID = .init(), kind: ChatBubbleKind, text: String) {
        self.id = id
        self.kind = kind
        self.text = text
    }
}
