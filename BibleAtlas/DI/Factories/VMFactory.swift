//
//  VMFactory.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/28/25.
//

import UIKit
import RxSwift

struct UseCases {
    let auth: AuthUsecaseProtocol
    let user: UserUsecaseProtocol
    let place: PlaceUsecaseProtocol
    let map: MapUsecaseProtocol
}

protocol VMFactoryProtocol {
    func makeHomeBottomSheetVM() -> HomeBottomSheetViewModelProtocol;
        
    func makeHomeContentVM() -> HomeContentViewModelProtocol;
    
    func makeSearchResultVM(keyword$: Observable<String>, isSearchingMode$: Observable<Bool>, cancelButtonTapped$: Observable<Void>) -> SearchResultViewModelProtocol
    
    func makeSearchReadyVM() -> SearchReadyViewModelProtocol
    
    func makeSearchBottomSheetVM() -> SearchBottomSheetViewModelProtocol;
    func makeLoginBottomSheetVM() -> LoginBottomSheetViewModelProtocol
    func makeMyCollectionBottomSheetVM(filter:PlaceFilter) -> MyCollectionBottomSheetViewModelProtocol
    
    func makePlaceDetailBottomSheetVM(placeId:String) -> PlaceDetailViewModelProtocol
    
    func makeMemoBottomSheetVM(placeId:String) -> MemoBottomSheetViewModelProtocol
    
    func makePlaceModificationBottomSheerVM(placeId:String) -> PlaceModificationBottomSheetViewModelProtocol
    
    func makePlaceTypesBottomSheetVM() -> PlaceTypesBottomSheetViewModelProtocol
    
    func makePlaceCharactersBottomSheetVM() -> PlaceCharactersBottomSheetViewModelProtocol
    
    func makePlacesByTypeBottomSheetVM(placeTypeName:PlaceTypeName) -> PlacesByTypeBottomSheetViewModelProtocol
    
    func makePlacesByCharacterBottomSheetVM(character:String) ->
        PlacesByCharacterBottomSheetViewModelProtocol
    
    func makeBibleVerseDetailBottomSheetVM(keyword:String) ->
        BibleVerseDetailBottomSheetViewModelProtocol
    
    func makeRecentSearchesBottomSheetVM() -> RecentSearchesBottomSheetViewModelProtocol
    
    func makePopularPlacesBottomSheetVM() -> PopularPlacesBottomSheetViewModelProtocol
    
    func makeMyPageBottomSheetVM() -> MyPageBottomSheetViewModelProtocol
    
    func makeAccountManagementBottomSheetVM() -> AccountManagementBottomSheetViewModelProtocol
    
    func makeReportBottomSheetVM(placeId:String, reportType:PlaceReportType) -> ReportBottomSheetViewModelProtocol
    
    func makeMainVM() -> MainViewModelProtocol
    
    
    func configure(navigator:BottomSheetNavigator, appCoordinator:AppCoordinatorProtocol)
}

final class VMFactory:VMFactoryProtocol{
    func makeRecentSearchesBottomSheetVM() -> RecentSearchesBottomSheetViewModelProtocol {
        let vm = RecentSearchesBottomSheetViewModel(navigator: navigator, recentSearchService: recentSearchService)
        return vm
    }
    
    func makeHomeContentVM() -> HomeContentViewModelProtocol {
        let vm = HomeContentViewModel(navigator: navigator, appStore: appStore, userUsecase: usecases?.user, authUseCase: usecases?.auth)
        return vm;
    }
    
    func makeSearchResultVM(keyword$: Observable<String>, isSearchingMode$: Observable<Bool>, cancelButtonTapped$: Observable<Void>) -> SearchResultViewModelProtocol {
        let vm = SearchResultViewModel(navigator: navigator, placeUsecase: usecases?.place, isSearchingMode$: isSearchingMode$, keyword$: keyword$, cancelButtonTapped$: cancelButtonTapped$, recentSearchService: recentSearchService)
        return vm;
    }
    
    func makeSearchReadyVM() -> SearchReadyViewModelProtocol {
        let vm = SearchReadyViewModel(navigator: navigator, placeUsecase: usecases?.place, recentSearchService: recentSearchService)
        return vm
    }
    
    func makeSearchBottomSheetVM() -> SearchBottomSheetViewModelProtocol {
        let vm = SearchBottomSheetViewModel(navigator: navigator, placeUsecase: usecases?.place)
        return vm
    }
    
    
    
    func makeBibleVerseDetailBottomSheetVM(keyword: String) -> BibleVerseDetailBottomSheetViewModelProtocol {
        let vm = BibleVerseDetailBottomSheetViewModel(navigator: navigator, keyword: keyword, placeUsecase: usecases?.place)
        return vm
    }
    
    func makePlaceTypesBottomSheetVM() -> PlaceTypesBottomSheetViewModelProtocol {
        let vm = PlaceTypesBottomSheetViewModel(navigator: navigator, placeUsecase: usecases?.place);
        return vm
    }
    
    func makePlaceCharactersBottomSheetVM() -> PlaceCharactersBottomSheetViewModelProtocol {
        let vm = PlaceCharactersBottomSheetViewModel(navigator: navigator,placeUsecase: usecases?.place);
        return vm;
    }
    
    func makePopularPlacesBottomSheetVM() -> PopularPlacesBottomSheetViewModelProtocol {
        let vm = PopularPlacesBottomSheetViewModel(navigator: navigator, placeUsecase: usecases?.place)
        return vm;
    }
    
    
    private weak var navigator:BottomSheetNavigator?;
    private weak var appCoordinator:AppCoordinatorProtocol?
    
    private var appStore:AppStoreProtocol?
    private var usecases:UseCases?
    private var notificationService: RxNotificationServiceProtocol?
    private var recentSearchService: RecentSearchServiceProtocol?
    
    init(appStore: AppStoreProtocol? = nil, usecases:UseCases? = nil, notificationService: RxNotificationServiceProtocol?, recentSearchService:RecentSearchServiceProtocol?) {
        self.appStore = appStore
        self.usecases = usecases
        self.notificationService = notificationService
        self.recentSearchService = recentSearchService
    }
    
    func makeHomeBottomSheetVM() -> HomeBottomSheetViewModelProtocol {
        let vm = HomeBottomSheetViewModel(navigator: navigator, appStore: appStore, authUseCase: usecases?.auth, recentSearchService: recentSearchService)
        return vm;
    }
    
    func makeLoginBottomSheetVM() -> LoginBottomSheetViewModelProtocol {
        let vm = LoginBottomSheetViewModel(navigator: navigator,usecase: usecases?.auth, appStore: appStore , notificationService: notificationService);
        return vm;
    }
    
    func makeMyCollectionBottomSheetVM(filter:PlaceFilter) -> MyCollectionBottomSheetViewModelProtocol {
        let vm = MyCollectionBottomSheetViewModel(navigator: navigator, filter: filter, userUsecase: usecases?.user);
        return vm;
    }
    
    func makePlaceDetailBottomSheetVM(placeId: String) -> PlaceDetailViewModelProtocol {
        let vm = PlaceDetailViewModel(navigator: navigator, placeId:placeId, placeUsecase: usecases?.place,  appStore:appStore, notificationService: notificationService );
        return vm;
    }
    
    func makeMemoBottomSheetVM(placeId: String) -> MemoBottomSheetViewModelProtocol {
        let vm = MemoBottomSheetViewModel(navigator: navigator, placeId: placeId,placeUsecase: usecases?.place, notificationService: notificationService)
        return vm;
    }
    
    func makePlaceModificationBottomSheerVM(placeId: String) -> PlaceModificationBottomSheetViewModelProtocol {
        let vm = PlaceModificationBottomSheetViewModel(navigator: navigator, placeId: placeId, placeUsecase: usecases?.place);
        return vm
    }
    
    func makePlacesByTypeBottomSheetVM(placeTypeName:PlaceTypeName) -> PlacesByTypeBottomSheetViewModelProtocol {
        let vm = PlacesByTypeBottomSheetViewModel(navigator:navigator, placeUsecase: usecases?.place, placeTypeName:placeTypeName)
        return vm;
    }
    
    func makePlacesByCharacterBottomSheetVM(character: String) -> PlacesByCharacterBottomSheetViewModelProtocol {
        let vm = PlacesByCharacterBottomSheetViewModel(navigator: navigator, character: character,placeUsecase: usecases?.place);
        return vm;
    }
    
    func makeMyPageBottomSheetVM() -> MyPageBottomSheetViewModelProtocol {
        let vm = MyPageBottomSheetViewModel(navigator: navigator, appStore: appStore)
        return vm;
    }
    
    func makeAccountManagementBottomSheetVM() -> AccountManagementBottomSheetViewModelProtocol {
        let vm = AccountManagementBottomSheetViewModel(navigator: navigator, appStore: appStore, appCoordinator: appCoordinator, authUsecase: usecases?.auth)
        return vm
    }
    
    func makeReportBottomSheetVM(placeId: String, reportType: PlaceReportType) -> ReportBottomSheetViewModelProtocol {
        let vm = ReportBottomSheetViewModel(navigator: navigator, reportType: reportType, placeUsecase: usecases?.place, placeId: placeId)
        
        return vm;
    }
    
    func makeMainVM() -> MainViewModelProtocol {
        let vm = MainViewModel(bottomSheetCoordinator: navigator, mapUseCase: usecases?.map, placeUsecase: usecases?.place, notificationService: notificationService)
        return vm
    }
    
    func configure(navigator: BottomSheetNavigator, appCoordinator:AppCoordinatorProtocol) {
        self.navigator = navigator;
        self.appCoordinator = appCoordinator;
    }
    
}

