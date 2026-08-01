import Foundation

enum ChatBotProgressLabel {
    /// 노드 이름 → 사용자용 진행 문구. 알 수 없는 이름은 기본값.
    /// 서버 실제 노드명 확인되면 이 매핑을 조정한다.
    static func label(forNode name: String) -> String {
        switch name {
        case "start":    return "요청 준비 중…"
        case "search":   return "관련 자료 찾는 중…"
        case "generate": return "답변 작성 중…"
        default:         return "생각 중…"
        }
    }
}
