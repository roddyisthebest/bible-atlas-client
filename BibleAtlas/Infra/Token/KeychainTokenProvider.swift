//
//  KeychainTokenProvider.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/18/25.
//

import Foundation
import KeychainAccess



final class KeychainTokenProvider: TokenProviderProtocol {
    
    var hasToken: Bool {
        (self.accessToken != nil) && (self.refreshToken != nil)
    }
    

    private let keychain: Keychain
    
    private enum Keys {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
    }

    init(service: String = Bundle.main.bundleIdentifier ?? "com.yourapp.default") {
        self.keychain = Keychain(service: service)
            .accessibility(.afterFirstUnlock) // 앱이 잠금 해제된 후에만 접근 가능
    }

    var accessToken: String? {
        try? keychain.get(Keys.accessToken)
    }

    var refreshToken: String? {
        try? keychain.get(Keys.refreshToken)
    }

    func save(accessToken: String, refreshToken: String) {
        do {
            try keychain.set(accessToken, key: Keys.accessToken)
            try keychain.set(refreshToken, key: Keys.refreshToken)
        } catch {
            print("❌ Failed to save tokens to Keychain: \(error)")
        }
    }

    func setAccessToken(accessToken: String) {
        do {
            try keychain.set(accessToken, key: Keys.accessToken)
        } catch {
            print("❌ Failed to update access token in Keychain: \(error)")
        }
    }

    func clear() -> Result<Bool, Error>{
        do {
               try keychain.remove(Keys.accessToken)
               try keychain.remove(Keys.refreshToken)
               return .success(true)
           } catch {
               print("❌ Failed to clear tokens from Keychain: \(error.localizedDescription)")
               return .failure(error)
        }
    }
}

