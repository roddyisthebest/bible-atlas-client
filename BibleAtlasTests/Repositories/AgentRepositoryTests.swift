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

    func test_stream_handlesMultipleJsonPayloadsInSingleEvent() async throws {
        // Server sometimes packs a node update + done payload as two data: lines in a single "done" event.
        // Our parser joins them with \n. Each line should be treated as its own event so the UI still
        // gets a progress update before the final done.
        let nodeJson = #"{"node":"non_bible_reject","update":{"answer":"x","recommended_questions":[]}}"#
        let doneJson = #"{"answer":"final answer","place_id_map":{},"recommended_questions":["q1"],"summary":null,"messages":[]}"#
        let joined = nodeJson + "\n" + doneJson
        let fake = FakeAgentStreamClient()
        fake.behavior = .events([SSEEvent(name: "done", data: joined)])
        let sut = AgentRepository(client: fake)

        let events = try await collect(sut.stream(request: .init(query: "q", summary: nil, messages: [])))

        XCTAssertEqual(events.count, 2)
        if case .node(let name) = events[0] {
            XCTAssertEqual(name, "non_bible_reject")
        } else { XCTFail("expected .node first") }
        if case .done(let payload) = events[1] {
            XCTAssertEqual(payload.answer, "final answer")
            XCTAssertEqual(payload.recommendedQuestions, ["q1"])
        } else { XCTFail("expected .done second") }
    }

    func test_stream_mapsToolEvent_startAndDone() async throws {
        let fake = FakeAgentStreamClient()
        fake.behavior = .events([
            SSEEvent(name: "tool", data: #"{"id":"call_1","name":"journey_route_search","phase":"start"}"#),
            SSEEvent(name: "tool", data: #"{"id":"call_1","name":"journey_route_search","phase":"done"}"#),
            SSEEvent(name: "done", data: #"{"answer":"ok","place_id_map":{},"recommended_questions":[],"summary":null,"messages":[]}"#),
        ])
        let sut = AgentRepository(client: fake)
        let events = try await collect(sut.stream(request: .init(query: "q", summary: nil, messages: [])))

        XCTAssertEqual(events.count, 3)
        if case .tool(let id, let name, let phase) = events[0] {
            XCTAssertEqual(id, "call_1")
            XCTAssertEqual(name, "journey_route_search")
            XCTAssertEqual(phase, .start)
        } else { XCTFail("expected .tool start") }
        if case .tool(_, _, let phase) = events[1] {
            XCTAssertEqual(phase, .done)
        } else { XCTFail("expected .tool done") }
        if case .done = events[2] {} else { XCTFail("expected .done") }
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
