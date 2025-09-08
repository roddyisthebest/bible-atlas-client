//
//  AppBootstrapper.swift
//  BibleAtlas
//
//  Created by 배성연 on 9/8/25.
//

import UIKit

@MainActor
final class AppBootstrapper {
    private let container: DIContainer
    private(set) var appCoordinator: AppCoordinatorProtocol?

    init(container: DIContainer) { self.container = container }

    func makeRoot(window: UIWindow) -> UIViewController {
        // wire window service & app coordinator
        let windowService = RealWindowService(window: window)
        let appCoordinator = AppCoordinator(
            appStore: container.appStore,
            vmFactory: container.vmFactory,
            vcFactory: container.vcFactory,
            notificationService: container.notificationService,
            bottomSheetCoordinator: container.bottomSheetCoordinator,
            windowService: windowService
        )
        
        self.appCoordinator = appCoordinator                     


        container.vmFactory.configure(navigator: container.bottomSheetCoordinator, appCoordinator: appCoordinator)

        // gate → ok 시 초기화 후 메인 진입
        let healthChecker = HealthCheckService(baseURLString: container.env.baseURL.absoluteString)
        let gateVC = AppGateViewController(healthChecker: healthChecker) { [weak self] in

            guard let self, let coordinator = self.appCoordinator else { return }
            Task {
                let initializer = AppInitializer(tokenProvider: self.container.tokenProvider, appStore: self.container.appStore, userApiService: self.container.userApiService)
                await initializer.restoreSessionIfPossible()
                coordinator.start()
            }
        }
        return gateVC
    }
}
