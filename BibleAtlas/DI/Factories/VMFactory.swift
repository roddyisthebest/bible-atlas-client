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
    let report: ReportUsecaseProtocol
}

protocol VMFactoryProtocol {
    func makeHomeBottomSheetVM() -> HomeBottomSheetViewModelProtocol;
        
    func makeHomeContentVM() -> HomeContentViewModelProtocol;
    
    func makeSearchResultVM(keyword$: Observable<String>, isSearchingMode$: Observable<Bool>, cancelButtonTapped$: Observable<Void>) -> SearchResultViewModelProtocol
    
    func makeSearchReadyVM() -> SearchReadyViewModelProtocol
    
    func makeLoginBottomSheetVM() -> LoginBottomSheetViewModelProtocol
    func makeMyCollectionBottomSheetVM(filter:PlaceFilter) -> MyCollectionBottomSheetViewModelProtocol
    
    func makePlaceDetailBottomSheetVM(placeId:String) -> PlaceDetailViewModelProtocol
    
    func makeMemoBottomSheetVM(placeId:String) -> MemoBottomSheetViewModelProtocol
    
    func makePlaceModificationBottomSheerVM(placeId:String) -> PlaceModificationBottomSheetViewModelProtocol
    
    func makePlaceTypesBottomSheetVM() -> PlaceTypesBottomSheetViewModelProtocol
    
    func makePlaceCharactersBottomSheetVM() -> PlaceCharactersBottomSheetViewModelProtocol
    
    func makeBiblesBottomSheetVM() -> BiblesBottomSheetViewModelProtocol

    func makePlacesByTypeBottomSheetVM(placeTypeName:PlaceTypeName) -> PlacesByTypeBottomSheetViewModelProtocol
    
    func makePlacesByCharacterBottomSheetVM(character:String) ->
        PlacesByCharacterBottomSheetViewModelProtocol
    
    func makePlacesByBibleBottomSheetVM(bible:BibleBook) -> PlacesByBibleBottomSheetViewModelProtocol
    
    func makeBibleVerseDetailBottomSheetVM(bibleBook:BibleBook, keyword:String, placeName:String?) ->
        BibleVerseDetailBottomSheetViewModelProtocol
    
    func makeRecentSearchesBottomSheetVM() -> RecentSearchesBottomSheetViewModelProtocol
    
    func makePopularPlacesBottomSheetVM() -> PopularPlacesBottomSheetViewModelProtocol
    
    func makeMyPageBottomSheetVM() -> MyPageBottomSheetViewModelProtocol
    
    func makeAccountManagementBottomSheetVM() -> AccountManagementBottomSheetViewModelProtocol
    
    func makePlaceReportBottomSheetVM(placeId:String, reportType:PlaceReportType) -> PlaceReportBottomSheetViewModelProtocol
    
    func makeBibleBookVerseListBottomSheetVM(placeId:String, bibleBook:BibleBook?) -> BibleBookVerseListBottomSheetViewModelProtocol
    
    
    func makeMainVM() -> MainViewModelProtocol
        
    func makeReportBottomSheetVM() -> ReportBottomSheetViewModelProtocol
    
    func configure(navigator:BottomSheetNavigator, appCoordinator:AppCoordinatorProtocol)
}

final class VMFactory:VMFactoryProtocol{
    func makeReportBottomSheetVM() -> ReportBottomSheetViewModelProtocol {
        let vm = ReportBottomSheetViewModel(navigator: navigator, reportUsecase: usecases?.report)
        return vm
    }
    
    func makeRecentSearchesBottomSheetVM() -> RecentSearchesBottomSheetViewModelProtocol {
        let vm = RecentSearchesBottomSheetViewModel(navigator: navigator, recentSearchService: recentSearchService, notificationService:  notificationService)
        return vm
    }
    
    func makeHomeContentVM() -> HomeContentViewModelProtocol {
        let vm = HomeContentViewModel(navigator: navigator, appStore: appStore, collectionStore: collectionStore, userUsecase: usecases?.user, authUseCase: usecases?.auth, recentSearchService: recentSearchService, notificationService: notificationService)
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
    
    func makeBibleVerseDetailBottomSheetVM(bibleBook:BibleBook, keyword: String, placeName:String?) -> BibleVerseDetailBottomSheetViewModelProtocol {
        let vm = BibleVerseDetailBottomSheetViewModel(navigator: navigator, bibleBook: bibleBook, keyword: keyword, placeName: placeName, placeUsecase: usecases?.place)
        return vm
    }
    
    func makeBiblesBottomSheetVM() -> BiblesBottomSheetViewModelProtocol {
        let vm = BiblesBottomSheetViewModel(navigator: navigator, placeUsecase: usecases?.place, notificationService: notificationService)
        return vm
    }
    
    func makePlaceTypesBottomSheetVM() -> PlaceTypesBottomSheetViewModelProtocol {
        let vm = PlaceTypesBottomSheetViewModel(navigator: navigator, placeUsecase: usecases?.place, notificationService: notificationService);
        return vm
    }
    
    func makePlaceCharactersBottomSheetVM() -> PlaceCharactersBottomSheetViewModelProtocol {
        let vm = PlaceCharactersBottomSheetViewModel(navigator: navigator,placeUsecase: usecases?.place, notificationService: notificationService);
        return vm;
    }
    
    func makePopularPlacesBottomSheetVM() -> PopularPlacesBottomSheetViewModelProtocol {
        let vm = PopularPlacesBottomSheetViewModel(navigator: navigator, placeUsecase: usecases?.place, notificationService: notificationService)
        return vm;
    }
    
    
    private weak var navigator:BottomSheetNavigator?;
    private weak var appCoordinator:AppCoordinatorProtocol?
    
    private var appStore:AppStoreProtocol?
    private var collectionStore:CollectionStoreProtocol?
    private var usecases:UseCases?
    private var notificationService: RxNotificationServiceProtocol?
    private var recentSearchService: RecentSearchServiceProtocol?
    
    init(appStore: AppStoreProtocol?, collectionStore:CollectionStoreProtocol?, usecases:UseCases? = nil, notificationService: RxNotificationServiceProtocol?, recentSearchService:RecentSearchServiceProtocol?) {
        self.appStore = appStore
        self.collectionStore = collectionStore
        self.usecases = usecases
        self.notificationService = notificationService
        self.recentSearchService = recentSearchService
    }
    
    func makeHomeBottomSheetVM() -> HomeBottomSheetViewModelProtocol {
        let vm = HomeBottomSheetViewModel(navigator: navigator, appStore: appStore, authUseCase: usecases?.auth, recentSearchService: recentSearchService, notificationService: notificationService)
        return vm;
    }
    
    func makeLoginBottomSheetVM() -> LoginBottomSheetViewModelProtocol {
        let vm = LoginBottomSheetViewModel(navigator: navigator,usecase: usecases?.auth, appStore: appStore , notificationService: notificationService);
        return vm;
    }
    
    func makeMyCollectionBottomSheetVM(filter:PlaceFilter) -> MyCollectionBottomSheetViewModelProtocol {
        let vm = MyCollectionBottomSheetViewModel(navigator: navigator, filter: filter, userUsecase: usecases?.user, notificationService: notificationService);
        return vm;
    }
    
    func makePlaceDetailBottomSheetVM(placeId: String) -> PlaceDetailViewModelProtocol {
        let vm = PlaceDetailViewModel(navigator: navigator, placeId:placeId, placeUsecase: usecases?.place, appStore:appStore, collectionStore: collectionStore, notificationService: notificationService );
        return vm;
    }
    
    func makeMemoBottomSheetVM(placeId: String) -> MemoBottomSheetViewModelProtocol {
        let vm = MemoBottomSheetViewModel(navigator: navigator, placeId: placeId,placeUsecase: usecases?.place, collectionStore: collectionStore, notificationService: notificationService)
        return vm;
    }
    
    func makePlaceModificationBottomSheerVM(placeId: String) -> PlaceModificationBottomSheetViewModelProtocol {
        let vm = PlaceModificationBottomSheetViewModel(navigator: navigator, placeId: placeId, placeUsecase: usecases?.place);
        return vm
    }
    
    func makePlacesByTypeBottomSheetVM(placeTypeName:PlaceTypeName) -> PlacesByTypeBottomSheetViewModelProtocol {
        let vm = PlacesByTypeBottomSheetViewModel(navigator:navigator, placeUsecase: usecases?.place, placeTypeName:placeTypeName, notificationService: notificationService)
        return vm;
    }
    
    func makePlacesByCharacterBottomSheetVM(character: String) -> PlacesByCharacterBottomSheetViewModelProtocol {
        let vm = PlacesByCharacterBottomSheetViewModel(navigator: navigator, character: character,placeUsecase: usecases?.place, notificationService: notificationService);
        return vm;
    }
    
    func makePlacesByBibleBottomSheetVM(bible:BibleBook) -> PlacesByBibleBottomSheetViewModelProtocol{
        let vm = PlacesByBibleBottomSheetViewModel(navigator: navigator, bible: bible, placeUsecase: usecases?.place, notificationService: notificationService)
        return vm
    }

    
    
    func makeMyPageBottomSheetVM() -> MyPageBottomSheetViewModelProtocol {
        let vm = MyPageBottomSheetViewModel(navigator: navigator, appStore: appStore)
        return vm;
    }
    
    func makeAccountManagementBottomSheetVM() -> AccountManagementBottomSheetViewModelProtocol {
        let vm = AccountManagementBottomSheetViewModel(navigator: navigator, appStore: appStore, appCoordinator: appCoordinator, authUsecase: usecases?.auth)
        return vm
    }
    
    func makePlaceReportBottomSheetVM(placeId: String, reportType: PlaceReportType) -> PlaceReportBottomSheetViewModelProtocol {
        let vm = PlaceReportBottomSheetViewModel(navigator: navigator, reportType: reportType, placeUsecase: usecases?.place, placeId: placeId)
        
        return vm;
    }
    
    func makeBibleBookVerseListBottomSheetVM(placeId:String, bibleBook:BibleBook?) -> BibleBookVerseListBottomSheetViewModelProtocol{
        let vm = BibleBookVerseListBottomSheetViewModel(navigator: navigator, placeId: placeId, bibleBook: bibleBook, placeUsecase: usecases?.place)
        return vm
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

