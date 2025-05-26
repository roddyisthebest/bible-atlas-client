//
//  ErrorHandlerService.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/26/25.
//

import Foundation


final class ErrorHandlerService: ErrorHandlerServiceProtocol {
    private let tokenProvider: TokenProviderProtocol
    private let appStore: AppStoreProtocol

    
    init(
        tokenProvider: TokenProviderProtocol,
        appStore: AppStoreProtocol
    ) {
        self.tokenProvider = tokenProvider
        self.appStore = appStore
    }

    func logoutDueToExpiredSession() async {
        let result = tokenProvider.clear()
        appStore.dispatch(.logout)
    }
}
