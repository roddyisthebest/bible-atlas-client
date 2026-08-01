import Foundation

struct SSEEvent: Equatable {
    let name: String        // "node", "done", "error", "message"(default)
    let data: String        // 여러 data: 라인은 \n 으로 join
}

/// 라인 단위로 소비, blank line 이 오면 지금까지 모인 이벤트를 반환하는 상태머신.
/// SSE 스펙: 빈 줄이 이벤트 구분자, "field: value" 형식.
final class SSELineParser {
    private var eventName = ""
    private var dataBuffer: [String] = []

    /// 라인 하나 소비. 빈 줄이면 지금까지 모인 이벤트 반환하고 리셋.
    func consume(line: String) -> SSEEvent? {
        if line.isEmpty {
            return flush()
        }
        if line.hasPrefix(":") { return nil }               // SSE 주석
        guard let colon = line.firstIndex(of: ":") else { return nil }
        let field = String(line[..<colon])
        var value = String(line[line.index(after: colon)...])
        if value.hasPrefix(" ") { value.removeFirst() }
        switch field {
        case "event": eventName = value
        case "data": dataBuffer.append(value)
        default: break                                       // id/retry 등 무시
        }
        return nil
    }

    /// 스트림 종료 시 남은 이벤트 flush. 남은 게 없으면 nil.
    func flush() -> SSEEvent? {
        guard !dataBuffer.isEmpty || !eventName.isEmpty else { return nil }
        let event = SSEEvent(
            name: eventName.isEmpty ? "message" : eventName,
            data: dataBuffer.joined(separator: "\n")
        )
        eventName = ""
        dataBuffer.removeAll()
        return event
    }
}
