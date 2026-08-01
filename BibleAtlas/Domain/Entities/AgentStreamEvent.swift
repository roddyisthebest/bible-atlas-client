import Foundation

enum ToolPhase: String, Codable {
    case start
    case done
}

enum AgentStreamEvent {
    case node(name: String)                                       // UX 진행 표시용
    case tool(id: String, name: String, phase: ToolPhase)         // 도구 호출 lifecycle — UX 전용
    case done(AgentDonePayload)                                   // 종결 이벤트
    case failure(message: String)                                 // 서버 error 이벤트 (정상 종결)
}
