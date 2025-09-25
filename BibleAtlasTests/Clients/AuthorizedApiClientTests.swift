//
//  AuthorizedApiClientTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/25/25.
//

import XCTest
import Alamofire
@testable import BibleAtlas

func makeStubbedSession() -> Alamofire.Session {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [StubURLProtocol.self]
    return Alamofire.Session(configuration: config)
}

// MARK: - Minimal 모델 (디코딩용)
private struct FooDTO: Decodable, Encodable, Equatable {
    let id: Int
    let name: String
}




final class AuthorizedApiClient_URLProtocolTests: XCTestCase {
    var sessionAdapter: AlamofireSessionAdapter!
    var tokenProvider: MockTokenProvider!
    var refresher: MockTokenRefresher!
    var errorHandler: MockErrorHandler!
    var sut: AuthorizedApiClient!
        
    
    override func setUp() {
        super.setUp()
        StubURLProtocol.reset()
        
        let afSession = makeStubbedSession()
        sessionAdapter = AlamofireSessionAdapter(session: afSession)
        tokenProvider = MockTokenProvider()
        refresher = MockTokenRefresher()
        errorHandler = MockErrorHandler()
        
        sut = AuthorizedApiClient(
            session: sessionAdapter,
            tokenProvider: tokenProvider,
            tokenRefresher: refresher,
            errorHandlerService: errorHandler
        )

    }
    
    override func tearDown() {
        sut = nil
        errorHandler = nil
        refresher = nil
        tokenProvider = nil
        sessionAdapter = nil
        StubURLProtocol.reset()
        super.tearDown()
    }
    
    func test_success_200_decodes() async {
          tokenProvider.accessToken = "t0"
          let url = URL(string: "https://example.com/foo")!
          let payload = try! JSONEncoder().encode(FooDTO(id: 1, name: "A"))
          StubURLProtocol.enqueue(url: url, stub: .init(statusCode: 200, headers: nil, data: payload, error: nil))

          let r: Result<FooDTO, NetworkError> = await sut.getData(url: url.absoluteString, parameters: nil)
          switch r {
          case .success(let dto):
              XCTAssertEqual(dto.id, 1)
              XCTAssertEqual(dto.name, "A")
          case .failure(let e):
              XCTFail("unexpected: \(e)")
          }
      }
    
    
    func test_401_then_refresh_success_retries_once() async {
           tokenProvider.accessToken = "old-token"
           refresher.outcome = .success("new-token")
        
           let url = URL(string: "https://example.com/bar")!
           // 첫 응답: 401
           StubURLProtocol.enqueue(url: url, stub: .init(statusCode: 401, headers: nil, data: Data(), error: nil))
           // 두 번째 응답: 200 with payload
           let payload = try! JSONEncoder().encode(FooDTO(id: 9, name: "Z"))
           StubURLProtocol.enqueue(url: url, stub: .init(statusCode: 200, headers: nil, data: payload, error: nil))

           let r: Result<FooDTO, NetworkError> = await sut.getData(url: url.absoluteString, parameters: nil)

           switch r {
           case .success(let dto):
               XCTAssertEqual(dto.id, 9)
               XCTAssertEqual(tokenProvider.accessToken, "new-token")
               XCTAssertFalse(errorHandler.didLogout)
           case .failure(let e):
               XCTFail("unexpected: \(e)")
           }
       }
    
    
    func test_401_then_refresh_failure_logs_out_and_returns_401() async {
           tokenProvider.accessToken = "old"
           refresher.outcome = .failure

           let url = URL(string: "https://example.com/baz")!
           StubURLProtocol.enqueue(url: url, stub: .init(statusCode: 401, headers: nil, data: Data(), error: nil))

           let r: Result<FooDTO, NetworkError> = await sut.getData(url: url.absoluteString, parameters: nil)

           if case .failure(let err) = r {
               XCTAssertTrue(errorHandler.didLogout)
               if case .serverError(let code) = err {
                   XCTAssertEqual(code, 401)
               } else { XCTFail("expected .serverError(401), got \(err)") }
           } else {
               XCTFail("should fail")
           }
       }
    
    
    func test_server_error_with_message_decodes() async {

        let url = URL(string: "https://example.com/err")!
        let errorMsg = "error msg"
        let statusCode = 400
        let server = try! JSONEncoder().encode(ErrorResponse(message: errorMsg, error: errorMsg, statusCode:statusCode ))
        StubURLProtocol.enqueue(url: url, stub: .init(statusCode: 400, headers: nil, data: server, error: nil))

         let r: Result<FooDTO, NetworkError> = await sut.getData(url: url.absoluteString, parameters: nil)

         if case .failure(let e) = r {
             switch e {
             case .serverErrorWithMessage(let er):
                 XCTAssertEqual(er.statusCode, 400)
                 XCTAssertEqual(er.message, errorMsg)
             default:
                 XCTFail("expected .serverErrorWithMessage, got \(e)")
             }
         } else { XCTFail("should fail") }
     }
    
    
    
    func test_decode_failure() async {
         let url = URL(string: "https://example.com/dec")!
         let wrong = #"{"nope":1}"#.data(using: .utf8)!
         StubURLProtocol.enqueue(url: url, stub: .init(statusCode: 200, headers: nil, data: wrong, error: nil))

         let r: Result<FooDTO, NetworkError> = await sut.getData(url: url.absoluteString, parameters: nil)
         if case .failure(let e) = r {
             if case .failToDecode = e { } else { XCTFail("expected .failToDecode, got \(e)") }
         } else { XCTFail("should fail") }
     }
    
    
    func test_client_error_maps_to_clientError() async {
        let url = URL(string: "https://example.com/boom")!
        // URLProtocol로 에러를 직접 던지려면 error를 채워주자.
        let err = URLError(.timedOut)
        StubURLProtocol.enqueue(url: url, stub: .init(statusCode: 0, headers: nil, data: nil, error: err))

        let r: Result<FooDTO, NetworkError> = await sut.getData(url: url.absoluteString, parameters: nil)
        if case .failure(let e) = r {
            if case .clientError = e { } else { XCTFail("expected .clientError, got \(e)") }
        } else { XCTFail("should fail") }
    }
    
    func test_getRawData_success_and_serverError() async {
         let url1 = URL(string: "https://example.com/raw1")!
         StubURLProtocol.enqueue(url: url1, stub: .init(statusCode: 200, headers: nil, data: Data("hi".utf8), error: nil))
         let r1 = await sut.getRawData(url: url1.absoluteString, parameters: nil)
         if case .success(let d) = r1 { XCTAssertEqual(String(data: d, encoding: .utf8), "hi") } else { XCTFail() }

         let url2 = URL(string: "https://example.com/raw2")!
         StubURLProtocol.enqueue(url: url2, stub: .init(statusCode: 500, headers: nil, data: Data("oops".utf8), error: nil))
         let r2 = await sut.getRawData(url: url2.absoluteString, parameters: nil)
         if case .failure(let e) = r2 {
             if case .serverError(let code) = e { XCTAssertEqual(code, 500) } else { XCTFail() }
         } else { XCTFail() }
     }

    
    
}
