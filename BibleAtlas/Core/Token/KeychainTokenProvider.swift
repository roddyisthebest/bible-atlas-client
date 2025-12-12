//  KeychainTokenProvider.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/18/25.
//

import Foundation
import KeychainAccess

// Keychain을 감싸는 프로토콜 – 테스트용으로 실패/성공 시나리오 분리 가능
protocol KeychainStore {
    func get(_ key: String) throws -> String?
    func set(_ value: String, for key: String) throws
    func remove(_ key: String) throws
}

// 실제 앱에서 쓰는 구현
struct RealKeychainStore: KeychainStore {
    private let keychain: Keychain

    init(service: String) {
        self.keychain = Keychain(service: service)
            .accessibility(.afterFirstUnlock)
    }

    func get(_ key: String) throws -> String? {
        try keychain.get(key)
    }

    func set(_ value: String, for key: String) throws {
        try keychain.set(value, key: key)
    }

    func remove(_ key: String) throws {
        try keychain.remove(key)
    }
}

final class KeychainTokenProvider: TokenProviderProtocol {

    var hasToken: Bool {
        (self.accessToken != nil) && (self.refreshToken != nil)
    }

    private let store: KeychainStore

    private enum Keys {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
    }

    // 실제 앱에서 쓰는 기본 init (default argument 포함)
    init(service: String = Bundle.main.bundleIdentifier ?? "com.yourapp.default") {
        self.store = RealKeychainStore(service: service)
    }

    // 테스트용으로 Store를 직접 주입
    init(store: KeychainStore) {
        self.store = store
    }

    var accessToken: String? {
        // 성공/실패 둘 다 테스트 가능 (성공하는 store / 항상 throw 하는 store)
        try? store.get(Keys.accessToken)
    }

    var refreshToken: String? {
        try? store.get(Keys.refreshToken)
    }

    func save(accessToken: String, refreshToken: String) {
        do {
            try store.set(accessToken, for: Keys.accessToken)
            try store.set(refreshToken, for: Keys.refreshToken)
        } catch {
            print("❌ Failed to save tokens to Keychain: \(error)")
        }
    }

    func setAccessToken(accessToken: String) {
        do {
            try store.set(accessToken, for: Keys.accessToken)
        } catch {
            print("❌ Failed to update access token in Keychain: \(error)")
        }
    }

    func clear() -> Result<Void, Error> {
        do {
            try store.remove(Keys.accessToken)
            try store.remove(Keys.refreshToken)
            return .success(())
        } catch {
            print("❌ Failed to clear tokens from Keychain: \(error.localizedDescription)")
            return .failure(error)
        }
    }
}
