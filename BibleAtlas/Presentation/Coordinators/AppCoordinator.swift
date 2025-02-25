//
//  AppCoordinator.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/5/25.
//

import UIKit


protocol CoordinatorProtocol: AnyObject{
    func start()

}

protocol AppCoordinatorProtocol:CoordinatorProtocol {
    func showLoginFlow();
    func showMainTabFlow();
}


class AppCoordinator:AppCoordinatorProtocol{
        
    var window: UIWindow?

    init(window: UIWindow? = nil) {
        self.window = window
    }
    
    
    func showLoginFlow() {
        let session = DefaultSession();
        let networkManager = NetworkManager(session: session, authManager: AuthManager.shared)
        
        let authNetworkManager = AuthNetworkManager(manager: networkManager, url: "https://api.bible-atlas.com/auth")
        
        let authRP = AuthRepository(networkManager: authNetworkManager);
        
        let authUC = AuthUsecase(repository:authRP);
        let loginVM = LoginViewModel(authUsecase: authUC);
        let loginVC = LoginViewController(loginViewModel: loginVM, appCoordinator: self);
        
        
        window?.rootViewController = loginVC;
        window?.makeKeyAndVisible();
    }
    
    func showMainTabFlow() {
        

        let mainTabBarController = MainTabBarController()

        window?.rootViewController = mainTabBarController
        window?.makeKeyAndVisible()
    }
    
    func start(){
        showMainTabFlow()
    }
    
  
    
     deinit{
         print("deinit:app-coodinator")
     }
}
