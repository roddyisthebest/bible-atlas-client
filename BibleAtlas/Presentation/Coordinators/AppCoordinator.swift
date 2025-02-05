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
        let mainTabBarController = UITabBarController()
        let homeVC = HomeViewController()
        let searchVC = SearchViewController()
        let myInfoViewVC = MyInfoViewController()
        
        homeVC.tabBarItem = UITabBarItem(title: "홈", image: UIImage(systemName: "house.fill"), tag: 0)
        searchVC.tabBarItem = UITabBarItem(title: "검색", image: UIImage(systemName: "magnifyingglass"), tag: 1)
        myInfoViewVC.tabBarItem = UITabBarItem(title: "프로필", image: UIImage(systemName: "person.fill"), tag: 2)

        mainTabBarController.viewControllers = [homeVC, searchVC, myInfoViewVC]

        window?.rootViewController = mainTabBarController
        window?.makeKeyAndVisible()
    }
    
    func start(){
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
    
  
    
     deinit{
         print("deinit:app-coodinator")
     }
}
