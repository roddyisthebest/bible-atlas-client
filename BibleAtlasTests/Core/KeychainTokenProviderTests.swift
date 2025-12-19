//  KeychainTokenProviderTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/6/25.
//

import XCTest
@testable import BibleAtlas

// MARK: - Mock Stores

private enum DummyError: Error, Equatable {
    case alwaysFail
}

// 항상 성공하는 Store
final class MockKeychainStoreSuccess: KeychainStore {
    private var storage: [String: String] = [:]

    func get(_ key: String) throws -> String? {
        storage[key]
    }

    func set(_ value: String, for key: String) throws {
        storage[key] = value
    }

    func remove(_ key: String) throws {
        storage.removeValue(forKey: key)
    }
}

// 항상 실패하는 Store (에러 분기 전용)
final class MockKeychainStoreFailure: KeychainStore {
    func get(_ key: String) throws -> String? {
        throw DummyError.alwaysFail
    }

    func set(_ value: String, for key: String) throws {
        throw DummyError.alwaysFail
    }

    func remove(_ key: String) throws {
        throw DummyError.alwaysFail
    }
}

// MARK: - Tests

final class KeychainTokenProviderTests: XCTestCase {

    // MARK: - 기본 상태 / hasToken / getter 성공 경로

    func test_hasToken_false_whenTokensEmpty() {
        let store = MockKeychainStoreSuccess()
        let sut = KeychainTokenProvider(store: store)

        XCTAssertFalse(sut.hasToken)
        XCTAssertNil(sut.accessToken)
        XCTAssertNil(sut.refreshToken)
    }

    func test_save_setsTokens_and_hasTokenBecomesTrue() {
        let store = MockKeychainStoreSuccess()
        let sut = KeychainTokenProvider(store: store)

        sut.save(accessToken: "access", refreshToken: "refresh")

        XCTAssertTrue(sut.hasToken)
        XCTAssertEqual(sut.accessToken, "access")
        XCTAssertEqual(sut.refreshToken, "refresh")
    }

    func test_setAccessToken_updatesOnlyAccessToken() {
        let store = MockKeychainStoreSuccess()
        let sut = KeychainTokenProvider(store: store)

        sut.save(accessToken: "old-access", refreshToken: "refresh")
        sut.setAccessToken(accessToken: "new-access")

        XCTAssertEqual(sut.accessToken, "new-access")
        XCTAssertEqual(sut.refreshToken, "refresh")
        XCTAssertTrue(sut.hasToken)
    }

    func test_clear_success_removesTokens_andReturnsSuccess() {
        let store = MockKeychainStoreSuccess()
        let sut = KeychainTokenProvider(store: store)

        sut.save(accessToken: "access", refreshToken: "refresh")
        XCTAssertTrue(sut.hasToken)

        let result = sut.clear()

        switch result {
        case .success:
            break
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }

        XCTAssertFalse(sut.hasToken)
        XCTAssertNil(sut.accessToken)
        XCTAssertNil(sut.refreshToken)
    }

    // MARK: - getter 실패 경로 커버 (try? store.get ...)

    func test_accessToken_returnsNil_whenStoreThrows() {
        let store = MockKeychainStoreFailure()
        let sut = KeychainTokenProvider(store: store)

        // store.get 이 항상 throw → try? → nil
        XCTAssertNil(sut.accessToken)
    }

    func test_refreshToken_returnsNil_whenStoreThrows() {
        let store = MockKeychainStoreFailure()
        let sut = KeychainTokenProvider(store: store)

        XCTAssertNil(sut.refreshToken)
    }

    // MARK: - save 실패 경로 커버 (catch 안 분기)

    func test_save_handlesError_whenStoreThrows() {
        let store = MockKeychainStoreFailure()
        let sut = KeychainTokenProvider(store: store)

        // throw 나도 crash 안 나고 그냥 catch 분기만 탐
        sut.save(accessToken: "access", refreshToken: "refresh")

        // store가 항상 실패하므로 토큰은 여전히 nil
        XCTAssertNil(sut.accessToken)
        XCTAssertNil(sut.refreshToken)
        XCTAssertFalse(sut.hasToken)
    }

    // MARK: - setAccessToken 실패 경로 커버

    func test_setAccessToken_handlesError_whenStoreThrows() {
        let successStore = MockKeychainStoreSuccess()
        let failureStore = MockKeychainStoreFailure()

        // 1) 우선 성공하는 store로 토큰 세팅
        let sutSuccess = KeychainTokenProvider(store: successStore)
        sutSuccess.save(accessToken: "access", refreshToken: "refresh")
        XCTAssertTrue(sutSuccess.hasToken)

        // 2) 실패 store로 다시 만들고 setAccessToken 호출 → throw → catch 분기 타기만 하면 됨
        let sutFailure = KeychainTokenProvider(store: failureStore)
        sutFailure.setAccessToken(accessToken: "new-access")

        // 실패 store라 토큰은 여전히 nil
        XCTAssertNil(sutFailure.accessToken)
        XCTAssertNil(sutFailure.refreshToken)
        XCTAssertFalse(sutFailure.hasToken)
    }

    // MARK: - clear 실패 경로 커버

    func test_clear_returnsFailure_whenStoreThrows() {
        let store = MockKeychainStoreFailure()
        let sut = KeychainTokenProvider(store: store)

        let result = sut.clear()

        switch result {
        case .success:
            XCTFail("Expected failure, but got success")
        case .failure(let error):
            XCTAssertNotNil(error)
        }
    }

    // MARK: - default initializer 경로 커버 (RealKeychainStore + default argument)

    func test_defaultInitializer_usesRealKeychainStore_andWorks() {
        // 이 호출이 바로 "default argument + RealKeychainStore" 경로
        let sut = KeychainTokenProvider()

        // 현재 상태 백업 (혹시 실제 앱에서 이미 저장된 토큰이 있을 수 있으니)
        let originalAccess = sut.accessToken
        let originalRefresh = sut.refreshToken

        sut.save(accessToken: "default-access", refreshToken: "default-refresh")

        XCTAssertEqual(sut.accessToken, "default-access")
        XCTAssertEqual(sut.refreshToken, "default-refresh")
        XCTAssertTrue(sut.hasToken)

        // 정리: 테스트가 끝나면 원래 상태로 복구 (없으면 clear만)
        _ = sut.clear()
        if let originalAccess, let originalRefresh {
            sut.save(accessToken: originalAccess, refreshToken: originalRefresh)
        }
    }
    
    
    // MARK: - service initializer 경로 커버 (RealKeychainStore + service argument)

    func test_init_withCustomService_usesGivenService() {
        // given
        let service = "com.bibleatlas.tests.keychaintokenprovider"

        // when
        let sut = KeychainTokenProvider(service: service)

        // then
        // 실제로는 service를 직접 확인할 수는 없지만,
        // 이 init을 통해 만들어진 인스턴스가 정상 동작하는지만 보면 됨.
        sut.save(accessToken: "access-init-service", refreshToken: "refresh-init-service")

        XCTAssertEqual(sut.accessToken, "access-init-service")
        XCTAssertEqual(sut.refreshToken, "refresh-init-service")

        // 정리 – 혹시 모를 keychain 찌꺼기 삭제
        _ = sut.clear()
    }

    
}
