//
//  AppInitializer.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/19/25.
//

import Foundation


protocol AppInitializerProtocol {
    func restoreSessionIfPossible() async
}


final class AppInitializer: AppInitializerProtocol {
    private let tokenProvider:TokenProviderProtocol
    private let appStore:AppStoreProtocol
    private let authApiService:AuthApiServiceProtocol
    
        
    init(tokenProvider: TokenProviderProtocol, appStore: AppStoreProtocol, authApiService: AuthApiServiceProtocol) {
        self.tokenProvider = tokenProvider
        self.appStore = appStore
        self.authApiService = authApiService
    }
    
    func restoreSessionIfPossible() async {
        guard tokenProvider.hasToken else {return}
        
        let result = await authApiService.getProfile();
        
        switch(result){
            case .success(let profile):
                appStore.dispatch(.login(profile))
            case .failure(let error):
                print(error.description)
        }
    }
    
}
