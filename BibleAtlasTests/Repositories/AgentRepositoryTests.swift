import XCTest
@testable import BibleAtlas

final class AgentRepositoryTests: XCTestCase {

    private func collect(_ stream: AsyncThrowingStream<AgentStreamEvent, Error>) async throws -> [AgentStreamEvent] {
        var out: [AgentStreamEvent] = []
        for try await e in stream { out.append(e) }
        return out
    }

    func test_stream_mapsNodeEvent() async throws {
        let fake = FakeAgentStreamClient()
        fake.behavior = .events([
            SSEEvent(name: "node", data: #"{"node":"search"}"#),
            SSEEvent(name: "done", data: #"{"answer":"hi","place_id_map":{},"recommended_questions":[],"summary":null,"messages":[]}"#),
        ])
        let sut = AgentRepository(client: fake)
        let events = try await collect(sut.stream(request: .init(query: "q", summary: nil, messages: [])))

        XCTAssertEqual(events.count, 2)
        if case .node(let name) = events[0] {
            XCTAssertEqual(name, "search")
        } else { XCTFail("expected .node") }
        if case .done(let payload) = events[1] {
            XCTAssertEqual(payload.answer, "hi")
        } else { XCTFail("expected .done") }
    }

    func test_stream_finishesAfterDone_evenIfMoreEventsFollow() async throws {
        let fake = FakeAgentStreamClient()
        fake.behavior = .events([
            SSEEvent(name: "done", data: #"{"answer":"hi","place_id_map":{},"recommended_questions":[],"summary":null,"messages":[]}"#),
            SSEEvent(name: "node", data: #"{"node":"extra"}"#),
        ])
        let sut = AgentRepository(client: fake)
        let events = try await collect(sut.stream(request: .init(query: "q", summary: nil, messages: [])))

        XCTAssertEqual(events.count, 1)
    }

    func test_stream_mapsErrorEventAsFailure_andFinishes() async throws {
        let fake = FakeAgentStreamClient()
        fake.behavior = .events([
            SSEEvent(name: "error", data: #"{"detail":"quota exceeded"}"#),
            SSEEvent(name: "node", data: #"{"node":"never"}"#),
        ])
        let sut = AgentRepository(client: fake)
        let events = try await collect(sut.stream(request: .init(query: "q", summary: nil, messages: [])))

        XCTAssertEqual(events.count, 1)
        if case .failure(let message) = events[0] {
            XCTAssertEqual(message, "quota exceeded")
        } else { XCTFail("expected .failure") }
    }

    func test_stream_ignoresUnknownEventName() async throws {
        let fake = FakeAgentStreamClient()
        fake.behavior = .events([
            SSEEvent(name: "keepalive", data: "{}"),
            SSEEvent(name: "done", data: #"{"answer":"ok","place_id_map":{},"recommended_questions":[],"summary":null,"messages":[]}"#),
        ])
        let sut = AgentRepository(client: fake)
        let events = try await collect(sut.stream(request: .init(query: "q", summary: nil, messages: [])))
        XCTAssertEqual(events.count, 1)
        if case .done(let payload) = events[0] {
            XCTAssertEqual(payload.answer, "ok")
        } else { XCTFail("expected .done") }
    }

    func test_stream_throwsDecodingError_whenJsonMalformed() async {
        let fake = FakeAgentStreamClient()
        fake.behavior = .events([
            SSEEvent(name: "done", data: "{ not valid json"),
        ])
        let sut = AgentRepository(client: fake)
        do {
            _ = try await collect(sut.stream(request: .init(query: "q", summary: nil, messages: [])))
            XCTFail("expected throw")
        } catch let error as AgentStreamError {
            if case .decoding(let name, _, _) = error {
                XCTAssertEqual(name, "done")
            } else { XCTFail("expected .decoding, got \(error)") }
        } catch {
            XCTFail("unexpected error type: \(error)")
        }
    }

    func test_stream_propagatesClientError() async {
        struct BoomError: Error {}
        let fake = FakeAgentStreamClient()
        fake.behavior = .throwsError(BoomError())
        let sut = AgentRepository(client: fake)
        do {
            _ = try await collect(sut.stream(request: .init(query: "q", summary: nil, messages: [])))
            XCTFail("expected throw")
        } catch is BoomError {
            // pass
        } catch {
            XCTFail("unexpected error type: \(error)")
        }
    }
}
