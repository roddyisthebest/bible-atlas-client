//
//  DIContainer.swift
//  BibleAtlas
//
//  Created by 배성연 on 9/8/25.
//

import Foundation
import UIKit

// 모든 의존성을 한 곳에서 생성/보유 (lazy로 필요 시 초기화)
final class DIContainer {
    let env: AppEnvironment

    init(env: AppEnvironment) { self.env = env }

    // Stores
    lazy var appStore = AppStore()
    lazy var collectionStore = CollectionStore()
    

    // System / Services
    lazy var session = DefaultSession()
    lazy var tokenProvider = KeychainTokenProvider()
    lazy var tokenRefresher = TokenRefresher(
        session: session,
        tokenProvider: tokenProvider,
        refreshURL: env.baseURL.appendingPathComponent("auth/refresh-token").absoluteString
    )
    
    lazy var errorHandlerService = ErrorHandlerService(tokenProvider: tokenProvider, appStore: appStore)
    lazy var apiClient = AuthorizedApiClient(
        session: session,
        tokenProvider: tokenProvider,
        tokenRefresher: tokenRefresher,
        errorHandlerService: errorHandlerService
    )
    lazy var notificationService = RxNotificationService()
    lazy var context = PersistenceController.shared.container.viewContext
    lazy var recentSearchService = RecentSearchService(context: context)
    lazy var analytics: AnalyticsLogging = FirebaseAnalyticsLogger()


    // API Services
    lazy var authApiService = AuthApiService(apiClient: apiClient, url: env.baseURL.appendingPathComponent("auth").absoluteString)
    lazy var userApiService = UserApiService(apiClient: apiClient, url: env.baseURL.appendingPathComponent("user").absoluteString)
    lazy var placeApiService = PlaceApiService(apiClient: apiClient, url: env.baseURL.absoluteString)
    lazy var mapApiService = MapApiService(apiClient: apiClient, url: env.baseURL.absoluteString)
    lazy var reportApiService = ReportApiService(apiClient: apiClient, url: env.baseURL.absoluteString)

    // Repositories
    lazy var authRepository = AuthRepository(authApiService: authApiService)
    lazy var userRepository = UserRepository(userApiService: userApiService)
    lazy var placeRepository = PlaceRepository(placeApiService: placeApiService)
    lazy var mapRepository = MapRepository(mapApiService: mapApiService)
    lazy var reportRepository = ReportRepository(reportApiService: reportApiService)

    // Usecases
    lazy var authUsecase = AuthUsecase(repository: authRepository, tokenProvider: tokenProvider)
    lazy var userUsecase = UserUsecase(repository: userRepository)
    lazy var placeUsecase = PlaceUsecase(repository: placeRepository)
    lazy var mapUsecase = MapUsecase(repository: mapRepository)
    lazy var reportUsecase = ReportUsecase(repository: reportRepository)
    lazy var usecases = UseCases(auth: authUsecase, user: userUsecase, place: placeUsecase, map: mapUsecase, report: reportUsecase)

    // Factories & Coordinators
    lazy var vmFactory = VMFactory(appStore: appStore, collectionStore: collectionStore, usecases: usecases, notificationService: notificationService, recentSearchService: recentSearchService)
    lazy var vcFactory = VCFactory()
    
    lazy var bottomSheetCoordinator = BottomSheetCoordinator(vcFactory: vcFactory, vmFactory: vmFactory, notificationService: notificationService, analytics: analytics)
}

