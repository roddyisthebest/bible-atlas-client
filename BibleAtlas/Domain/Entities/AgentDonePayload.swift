import Foundation

struct AgentDonePayload: Decodable, Equatable {
    let answer: String
    let placeIdMap: [String: [String]]
    let recommendedQuestions: [String]
    let summary: String?
    let messages: [ChatMessage]

    enum CodingKeys: String, CodingKey {
        case answer
        case placeIdMap = "place_id_map"
        case recommendedQuestions = "recommended_questions"
        case summary
        case messages
    }
}
