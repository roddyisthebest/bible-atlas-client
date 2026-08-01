import XCTest
@testable import BibleAtlas

final class SSELineParserTests: XCTestCase {

    func test_consume_singleCompleteEvent_returnsEventOnBlankLine() {
        let sut = SSELineParser()
        XCTAssertNil(sut.consume(line: "event: node"))
        XCTAssertNil(sut.consume(line: "data: {\"node\":\"start\"}"))
        let event = sut.consume(line: "")
        XCTAssertEqual(event, SSEEvent(name: "node", data: "{\"node\":\"start\"}"))
    }

    func test_consume_multipleDataLines_joinsWithNewline() {
        let sut = SSELineParser()
        _ = sut.consume(line: "event: done")
        _ = sut.consume(line: "data: line1")
        _ = sut.consume(line: "data: line2")
        let event = sut.consume(line: "")
        XCTAssertEqual(event, SSEEvent(name: "done", data: "line1\nline2"))
    }

    func test_consume_commentLine_isIgnored() {
        let sut = SSELineParser()
        XCTAssertNil(sut.consume(line: ":keepalive"))
        XCTAssertNil(sut.consume(line: "event: node"))
        XCTAssertNil(sut.consume(line: "data: x"))
        let event = sut.consume(line: "")
        XCTAssertEqual(event, SSEEvent(name: "node", data: "x"))
    }

    func test_consume_defaultEventNameIsMessage_whenEventFieldMissing() {
        let sut = SSELineParser()
        _ = sut.consume(line: "data: hello")
        let event = sut.consume(line: "")
        XCTAssertEqual(event, SSEEvent(name: "message", data: "hello"))
    }

    func test_flush_returnsPendingEvent_whenNoTrailingBlankLine() {
        let sut = SSELineParser()
        _ = sut.consume(line: "event: done")
        _ = sut.consume(line: "data: end")
        let event = sut.flush()
        XCTAssertEqual(event, SSEEvent(name: "done", data: "end"))
    }

    func test_flush_returnsNil_whenBufferEmpty() {
        let sut = SSELineParser()
        XCTAssertNil(sut.flush())
    }

    func test_consume_resetsStateAfterEmit() {
        let sut = SSELineParser()
        _ = sut.consume(line: "event: node")
        _ = sut.consume(line: "data: {\"node\":\"a\"}")
        _ = sut.consume(line: "")
        _ = sut.consume(line: "event: done")
        _ = sut.consume(line: "data: {\"answer\":\"hi\"}")
        let event = sut.consume(line: "")
        XCTAssertEqual(event, SSEEvent(name: "done", data: "{\"answer\":\"hi\"}"))
    }

    func test_consume_stripsSingleLeadingSpaceOnValue() {
        let sut = SSELineParser()
        _ = sut.consume(line: "event: node")
        _ = sut.consume(line: "data:  double-space-value")
        let event = sut.consume(line: "")
        XCTAssertEqual(event, SSEEvent(name: "node", data: " double-space-value"))
    }

    func test_consume_ignoresUnknownField() {
        let sut = SSELineParser()
        _ = sut.consume(line: "id: 42")
        _ = sut.consume(line: "retry: 3000")
        _ = sut.consume(line: "event: node")
        _ = sut.consume(line: "data: x")
        let event = sut.consume(line: "")
        XCTAssertEqual(event, SSEEvent(name: "node", data: "x"))
    }
}
