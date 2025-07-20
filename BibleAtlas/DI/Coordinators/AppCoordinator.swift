//
//  AppCoordinator.swift
//  BibleAtlas
//
//  Created by 배성연 on 7/20/25.
//

import UIKit


protocol AppCoordinatorProtocol: AnyObject {
    func start()
    func logout()
}



final class AppCoordinator:AppCoordinatorProtocol {
    private let appStore: AppStoreProtocol
    private let vmFactory: VMFactoryProtocol
    private let vcFactory: VCFactoryProtocol
    private let notificationService: RxNotificationServiceProtocol
    private let bottomSheetCoordinator: BottomSheetNavigator?
    private let windowService: WindowServiceProtocol

    init(
         appStore: AppStoreProtocol,
         vmFactory: VMFactoryProtocol,
         vcFactory: VCFactoryProtocol,
         notificationService: RxNotificationServiceProtocol,
         bottomSheetCoordinator: BottomSheetNavigator?,
         windowService:WindowServiceProtocol
    ) {
        self.appStore = appStore
        self.vmFactory = vmFactory
        self.vcFactory = vcFactory
        self.notificationService = notificationService
        self.windowService = windowService
        self.bottomSheetCoordinator = bottomSheetCoordinator
    }

    func start() {

        let mainVM = vmFactory.makeMainVM();
        let mainVC = vcFactory.makeMainVC(vm: mainVM)
        mainVC.modalPresentationStyle = .custom
        
        bottomSheetCoordinator?.setPresenter(mainVC)
        windowService.attach(mainVC)

        DispatchQueue.main.async {
            self.bottomSheetCoordinator?.present(.home)
        }
        

    }

    func logout() {
        appStore.dispatch(.logout)
        start() // 또는 loginFlow()
    }
}


