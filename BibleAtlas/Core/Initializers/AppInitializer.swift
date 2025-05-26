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
    private let userApiService:UserApiServiceProtocol
    
        
    init(tokenProvider: TokenProviderProtocol, appStore: AppStoreProtocol, userApiService: UserApiServiceProtocol) {
        self.tokenProvider = tokenProvider
        self.appStore = appStore
        self.userApiService = userApiService
    }
    
    func restoreSessionIfPossible() async {
        guard tokenProvider.hasToken else {return}
        
        let result = await userApiService.getProfile();
        
        switch(result){
            case .success(let profile):
                appStore.dispatch(.login(profile))
            case .failure(let error):
                
                print(error.description)
        }
    }
    
}
