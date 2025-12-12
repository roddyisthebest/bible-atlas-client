import XCTest
@testable import BibleAtlas

final class HealthCheckServiceTests: XCTestCase {

    private var sut: HealthCheckService!
    private var baseURL: URL!
    private var healthURL: URL!

    override func setUp() {
        super.setUp()
        // URLSession.shared 트래픽을 StubURLProtocol로 후킹
        URLProtocol.registerClass(StubURLProtocol.self)
        StubURLProtocol.reset()

        baseURL = URL(string: "https://example.com")!
        healthURL = baseURL.appendingPathComponent("health")
        sut = HealthCheckService(baseURLString: baseURL.absoluteString)
    }

    override func tearDown() {
        sut = nil
        StubURLProtocol.reset()
        URLProtocol.unregisterClass(StubURLProtocol.self)
        baseURL = nil
        healthURL = nil
        super.tearDown()
    }

    // MARK: - 2xx 정상 응답

    func test_check_whenStatusOk_returnsOk() async throws {
        // given
        let dto = HealthDTO(status: "ok", timestamp: "2025-01-01T00:00:00Z")
        let data = try JSONEncoder().encode(dto)

        StubURLProtocol.enqueue(
            url: healthURL,
            stub: .init(
                statusCode: 200,
                headers: ["Content-Type": "application/json"],
                data: data,
                error: nil
            )
        )

        // when
        let result = try await sut.check()

        // then
        XCTAssertEqual(result, .ok)
    }

    func test_check_whenStatusMaintenance_returnsMaintenanceWithTimestamp() async throws {
        // given
        let dto = HealthDTO(status: "maintenance", timestamp: "2025-02-02T12:34:56Z")
        let data = try JSONEncoder().encode(dto)

        StubURLProtocol.enqueue(
            url: healthURL,
            stub: .init(
                statusCode: 200,
                headers: ["Content-Type": "application/json"],
                data: data,
                error: nil
            )
        )

        // when
        let result = try await sut.check()

        // then
        switch result {
        case .maintenance(let message):
            XCTAssertTrue(message.contains("2025-02-02T12:34:56Z"),
                          "message should contain timestamp, got: \(message)")
        default:
            XCTFail("Expected .maintenance, got \(result)")
        }
    }

    func test_check_whenStatusUnknown_returnsBlockedAccessRestricted() async throws {
        // given
        let dto = HealthDTO(status: "weird", timestamp: "2025-03-03T00:00:00Z")
        let data = try JSONEncoder().encode(dto)

        StubURLProtocol.enqueue(
            url: healthURL,
            stub: .init(
                statusCode: 200,
                headers: ["Content-Type": "application/json"],
                data: data,
                error: nil
            )
        )

        // when
        let result = try await sut.check()

        // then
        switch result {
        case .blocked(let message):
            XCTAssertEqual(message, "Access is restricted.")
        default:
            XCTFail("Expected .blocked, got \(result)")
        }
    }

    func test_check_whenInvalidJson_returnsBlockedParseFailed() async throws {
        // given (JSON 디코딩 실패 케이스)
        let data = Data("not-json".utf8)

        StubURLProtocol.enqueue(
            url: healthURL,
            stub: .init(
                statusCode: 200,
                headers: ["Content-Type": "application/json"],
                data: data,
                error: nil
            )
        )

        // when
        let result = try await sut.check()

        // then
        switch result {
        case .blocked(let message):
            XCTAssertEqual(message, "Failed to parse response.")
        default:
            XCTFail("Expected .blocked, got \(result)")
        }
    }

    // MARK: - Non-2xx + friendlyMessage

    func test_check_when503WithoutBody_usesFriendlyMessageFor503() async throws {
        // given (본문 없음, 503)
        StubURLProtocol.enqueue(
            url: healthURL,
            stub: .init(
                statusCode: 503,
                headers: ["Content-Type": "application/json"],
                data: Data(),   // 빈 바디
                error: nil
            )
        )

        // when
        let result = try await sut.check()

        // then
        switch result {
        case .blocked(let message):
            XCTAssertEqual(message, "Service unavailable. Please try again later. (503)")
        default:
            XCTFail("Expected .blocked, got \(result)")
        }
    }

    func test_check_when400WithNestErrorArray_usesServerMessageJoined() async throws {
        // given: NestJS 스타일 에러 바디
        let json: [String: Any] = [
            "message": ["first error", "second error"],
            "statusCode": 400,
            "error": "Bad Request"
        ]
        let data = try JSONSerialization.data(withJSONObject: json)

        StubURLProtocol.enqueue(
            url: healthURL,
            stub: .init(
                statusCode: 400,
                headers: ["Content-Type": "application/json"],
                data: data,
                error: nil
            )
        )

        // when
        let result = try await sut.check()

        // then
        switch result {
        case .blocked(let message):
            XCTAssertTrue(message.contains("first error"),
                          "message should contain 'first error', got: \(message)")
            XCTAssertTrue(message.contains("second error"),
                          "message should contain 'second error', got: \(message)")
            XCTAssertTrue(message.hasSuffix("(400)"),
                          "message should end with '(400)', got: \(message)")
        default:
            XCTFail("Expected .blocked, got \(result)")
        }
    }

    // MARK: - URLError 매핑

    func test_check_whenTimedOut_returnsBlockedWithTimeoutMessage() async throws {
        // given
        StubURLProtocol.enqueue(
            url: healthURL,
            stub: .init(
                statusCode: 0,
                headers: nil,
                data: nil,
                error: URLError(.timedOut)
            )
        )

        // when
        let result = try await sut.check()

        // then
        switch result {
        case .blocked(let message):
            XCTAssertEqual(
                message,
                "Request timed out. Please check your connection and try again."
            )
        default:
            XCTFail("Expected .blocked with timeout message, got \(result)")
        }
    }

    func test_check_whenNoInternet_returnsBlockedWithNoInternetMessage() async throws {
        // given
        StubURLProtocol.enqueue(
            url: healthURL,
            stub: .init(
                statusCode: 0,
                headers: nil,
                data: nil,
                error: URLError(.notConnectedToInternet)
            )
        )

        // when
        let result = try await sut.check()

        // then
        switch result {
        case .blocked(let message):
            XCTAssertEqual(message, "No internet connection.")
        default:
            XCTFail("Expected .blocked with no internet message, got \(result)")
        }
    }

    func test_check_whenCannotReachHost_returnsBlockedWithCannotReachServerMessage() async throws {
        // given
        StubURLProtocol.enqueue(
            url: healthURL,
            stub: .init(
                statusCode: 0,
                headers: nil,
                data: nil,
                error: URLError(.cannotConnectToHost)
            )
        )

        // when
        let result = try await sut.check()

        // then
        switch result {
        case .blocked(let message):
            XCTAssertEqual(message, "Cannot reach the server.")
        default:
            XCTFail("Expected .blocked with 'Cannot reach the server.', got \(result)")
        }
    }

    func test_check_whenUnexpectedError_returnsBlockedWithUnexpectedMessage() async throws {
        // given: URLError가 아닌 다른 Error
        struct DummyError: Error {}
        StubURLProtocol.enqueue(
            url: healthURL,
            stub: .init(
                statusCode: 0,
                headers: nil,
                data: nil,
                error: DummyError()
            )
        )

        // when
        let result = try await sut.check()

        // then
        switch result {
        case .blocked(let message):
            XCTAssertTrue(
                message.starts(with: "Unexpected error:"),
                "message should start with 'Unexpected error:', got: \(message)"
            )
        default:
            XCTFail("Expected .blocked with unexpected error message, got \(result)")
        }
    }
}
