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
    private var deepLinkHandler: DeepLinkHandling?
    private var container: DIContainer!
    private var bootstrapper: AppBootstrapper!


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let ws = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: ws)

        // 1) 환경 + 컨테이너 + 부트스트랩
        let env = AppEnvironment(baseURLString: Constants.shared.url, geoJSONURLString: Constants.shared.geoJsonUrl)
        self.container = DIContainer(env: env)
        self.bootstrapper = AppBootstrapper(container: self.container)

        let root = self.bootstrapper.makeRoot(window: window)
        
        window.rootViewController = root
        window.makeKeyAndVisible()
        self.window = window
        
        // Wire DeepLink handler after DI is ready
        let parser = DefaultDeepLinkParser()
        let mapper = DefaultDeepLinkToBottomSheetMapper()
        let navigator = container.bottomSheetCoordinator
        let analytics = container.analytics;
        self.deepLinkHandler = DeepLinkHandler(parser: parser, mapper: mapper, navigator: navigator, analytics: analytics)
        
        // Handle any pending URL contexts on cold start
        if let urlContext = connectionOptions.urlContexts.first {
            deepLinkHandler?.handle(url: urlContext.url)
        }
        
        // Handle any user activities on cold start (e.g., universal links)
        if let activity = connectionOptions.userActivities.first {
            deepLinkHandler?.handle(userActivity: activity)
        }
    }
    
    // Restrict scene orientation to portrait only
    func windowScene(_ windowScene: UIWindowScene, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
    
    func scene(_ scene: UIScene,
               openURLContexts URLContexts: Set<UIOpenURLContext>) {

        guard let url = URLContexts.first?.url else { return }
        GIDSignIn.sharedInstance.handle(url)
        deepLinkHandler?.handle(url: url)
    }
    
    
    func scene(_ scene: UIScene,
               continue userActivity: NSUserActivity) {
        deepLinkHandler?.handle(userActivity: userActivity)
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

