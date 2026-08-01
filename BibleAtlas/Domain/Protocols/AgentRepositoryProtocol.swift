import Foundation

protocol AgentRepositoryProtocol {
    /// SSE 스트림. AsyncThrowingStream 로 이벤트 순차 방출.
    /// - 정상 종료: done 이벤트 방출 후 finish
    /// - 서버 error 이벤트: .failure 방출 후 finish
    /// - 네트워크/파싱 에러: throws
    func stream(request: AgentStreamRequest) -> AsyncThrowingStream<AgentStreamEvent, Error>
}
