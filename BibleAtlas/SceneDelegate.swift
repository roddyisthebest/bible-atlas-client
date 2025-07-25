//
//  SceneDelegate.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/3/25.
//

import UIKit
import GoogleSignIn

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var bottomSheetCoordinator: BottomSheetCoordinator?
    private var appCoordinator: AppCoordinatorProtocol?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        
        let session = DefaultSession();
        let appStore = AppStore();

        
        let tokenProvider = KeychainTokenProvider();
        let tokenRefresher  = TokenRefresher(session: session, tokenProvider: tokenProvider, refreshURL: "\(Constants.shared.url)/auth/refresh-token")
        let errorHandlerService = ErrorHandlerService(tokenProvider: tokenProvider, appStore: appStore)
        
        let apiClient = AuthorizedApiClient(session: session, tokenProvider: tokenProvider, tokenRefresher: tokenRefresher, errorHandlerService: errorHandlerService)
        
        let authApiService = AuthApiService(apiClient: apiClient, url: "\(Constants.shared.url)/auth")
        
        let userApiService = UserApiService(apiClient: apiClient, url: "\(Constants.shared.url)/user")
        
        let placeApiService = PlaceApiService(apiClient: apiClient, url: "\(Constants.shared.url)")
        
        
   
        
        Task{
            let appInitializer = AppInitializer(tokenProvider: tokenProvider, appStore: appStore, userApiService: userApiService);
            await appInitializer.restoreSessionIfPossible()
        }
        
        let authRepository = AuthRepository(authApiService: authApiService)
        let authUsecase = AuthUsecase(repository: authRepository, tokenProvider: tokenProvider)
        
        
        
        let userRepository = UserRepository(userApiService: userApiService)
        let userUsecase = UserUsecase(repository:userRepository)
        
        
        let placeRepository = PlaceRepository(placeApiService: placeApiService);
        
        let placeUsecase = PlaceUsecase(repository:placeRepository)
        
        let mapApiService = MapApiService(apiClient: apiClient, baseURL: "\(Constants.shared.geoJsonUrl)")
        let mapRepository = MapRepository(mapApiService: mapApiService)
        
        let mapUsecase = MapUsecase(repository: mapRepository);
        
        
        let usecases = UseCases(auth: authUsecase, user: userUsecase, place:placeUsecase, map:mapUsecase)
        
        let notificationService = RxNotificationService();
        
        let context = PersistenceController.shared.container.viewContext
        
        let recentSearchService = RecentSearchService(context: context)
        
        
        let vmFactory = VMFactory(appStore: appStore, usecases: usecases, notificationService: notificationService, recentSearchService: recentSearchService);
        let vcFactory = VCFactory();
            
        self.bottomSheetCoordinator = BottomSheetCoordinator(vcFactory: vcFactory, vmFactory: vmFactory, notificationService: notificationService);

        let windowService = RealWindowService(window: window);
        
        appCoordinator = AppCoordinator(appStore: appStore, vmFactory: vmFactory, vcFactory: vcFactory, notificationService: notificationService, bottomSheetCoordinator: bottomSheetCoordinator, windowService: windowService)

        
        
        vmFactory.configure(navigator: bottomSheetCoordinator!, appCoordinator: appCoordinator!)
        

        appCoordinator?.start()
        

       
    }
    
    func scene(_ scene: UIScene,
               openURLContexts URLContexts: Set<UIOpenURLContext>) {

        guard let url = URLContexts.first?.url else { return }
        GIDSignIn.sharedInstance.handle(url)
    }
    

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
    

}

