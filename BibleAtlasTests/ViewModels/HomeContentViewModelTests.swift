//
//  HomeContentBottomSheetViewModelTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 8/7/25.
//

import XCTest
import RxSwift
import RxRelay
import RxTest
import RxBlocking

@testable import BibleAtlas


final class MockAppStore:AppStoreProtocol{
    let state$: BehaviorRelay<AppState>
    
    init(state: AppState) {
        self.state$ = BehaviorRelay(value: state)
    }

    func dispatch(_ action: BibleAtlas.AppAction) {
        switch(action){
            case .login(let user):
                state$.accept(AppState(profile:user, isLoggedIn: true))
            case .logout:
                state$.accept(AppState(profile: nil, isLoggedIn: false))
        }
    }
}

final class MockCollectionStore: CollectionStoreProtocol {
    let state$ = BehaviorRelay<CollectionState>(
        value: CollectionState(
            likedPlaceIds: [], bookmarkedPlaceIds: [], memoedPlaceIds: []
        )
    )
    
    var lastAction: CollectionAction?
    
    func dispatch(_ action: CollectionAction) {
        lastAction = action
    }
}


final class MockUserUsecase: UserUsecaseProtocol {
    
    var myCollectionPlaceIdsResultToReturn: Result<MyCollectionPlaceIds, NetworkError>?
    
    var profileResultToReturn: Result<User, NetworkError>?
    
    func getMyCollectionPlaceIds() async -> Result<MyCollectionPlaceIds, NetworkError> {
        return myCollectionPlaceIdsResultToReturn ?? .failure(.clientError("test")) ;
    }
    
    func getPlaces(limit: Int?, page: Int?, filter: BibleAtlas.PlaceFilter?) async -> Result<BibleAtlas.ListResponse<BibleAtlas.Place>, BibleAtlas.NetworkError> {
        return  .failure(.clientError("test"))
    }
    
    func getProfile() async -> Result<BibleAtlas.User, BibleAtlas.NetworkError> {
        return profileResultToReturn ?? .failure(.clientError("test"))
    }
    
}


final class MockRecentSearchService: RecentSearchServiceProtocol {
    func fetch(limit: Int, page: Int?) -> Result<RecentSearchFetchResult, RecentSearchError> {
        
        fetchCalled = true
        return resultToReturn ?? .success(RecentSearchFetchResult(items:[], total:0, page:0))
    }
    
    func save(_ place: BibleAtlas.Place) -> Result<Void, BibleAtlas.RecentSearchError> {
        return .success(())
    }
    
    func delete(id: String) -> Result<Void, BibleAtlas.RecentSearchError> {
        .success(())
    }
    
    func clearAll() -> Result<Void, BibleAtlas.RecentSearchError> {
        .success(())
    }
    
    private let didChangeSubject$ = PublishSubject<Void>()
    public var didChanged$: Observable<Void> {
        didChangeSubject$.asObservable()
    }

    var fetchCalled = false

    var resultToReturn: Result<RecentSearchFetchResult, RecentSearchError>?

    
    init() {
    }
  
}





final class HomeContentViewModelTests: XCTestCase {
    
    var mockAppStore: MockAppStore!
    var mockCollectionStore: MockCollectionStore!
    var mockUserUsecase: MockUserUsecase!
    let appState = AppState(profile:nil, isLoggedIn: false)
    var scheduler: TestScheduler!
    var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        mockAppStore = MockAppStore(state: appState)
        mockCollectionStore = MockCollectionStore()
        mockUserUsecase = MockUserUsecase()
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()
    }
    
    
    func test_appStore_bind_sets_isLoggedIn_and_profile_correctly() {
            // Given
            let expectedUser = User(id: 123, name: "test", role: .USER, avatar: "test")
            mockUserUsecase.myCollectionPlaceIdsResultToReturn = .success(
                MyCollectionPlaceIds(liked: [], bookmarked: [], memoed: [])
            )

            let viewModel = HomeContentViewModel(
                navigator: nil,
                appStore: mockAppStore,
                collectionStore: mockCollectionStore,
                userUsecase: mockUserUsecase,
                authUseCase: nil,
                recentSearchService: nil,
                schedular: scheduler
            )

            let output = viewModel.transform(input: .init(
                collectionButtonTapped$: .empty(),
                placesByTypeButtonTapped$: .empty(),
                placesByCharacterButtonTapped$: .empty(),
                recentSearchCellTapped$: .empty(),
                moreRecentSearchesButtonTapped$: .empty()
            ))

            let isLoggedInObserver = scheduler.createObserver(Bool.self)
            let profileObserver = scheduler.createObserver(User?.self)

            output.isLoggedIn$
                .observe(on: scheduler)
                .bind(to: isLoggedInObserver)
                .disposed(by: disposeBag)

            output.profile$
                .observe(on: scheduler)
                .bind(to: profileObserver)
                .disposed(by: disposeBag)

            // When
            mockAppStore.dispatch(.login(expectedUser))
            scheduler.start()

            // Then
            let isLoggedInEvents = isLoggedInObserver.events.compactMap { $0.value.element }
            let profileEvents = profileObserver.events.compactMap { $0.value.element }

            XCTAssertEqual(isLoggedInEvents.last, true)
            XCTAssertEqual(profileEvents.last??.name, "test")
            XCTAssertEqual(mockCollectionStore.lastAction, .initialize(MyCollectionPlaceIds(liked: [], bookmarked: [], memoed: [])))
        }
    
    
    
    func test_collectionButtonTapped_shows_correct_screen_based_on_login_status() {
        // Given
        let mockNavigator = MockBottomSheetNavigator()

        
        let viewModel = HomeContentViewModel(
            navigator: mockNavigator,
            appStore: mockAppStore,
            collectionStore: mockCollectionStore,
            userUsecase: nil,
            authUseCase: nil,
            recentSearchService: nil,
            schedular: scheduler
        )
        
        let collectionButtonTapped$ = PublishRelay<PlaceFilter>();

        let input = HomeContentViewModel.Input(
            collectionButtonTapped$: collectionButtonTapped$.asObservable(),
            placesByTypeButtonTapped$: .empty(),
            placesByCharacterButtonTapped$: .empty(),
            recentSearchCellTapped$: .empty(),
            moreRecentSearchesButtonTapped$: .empty()
        )
        
        let _ = viewModel.transform(input: input)

        // When: 로그인 상태면
        let user = User(id:123, name:"test", role: .USER, avatar: "test")
        mockAppStore.dispatch(.login(user))
        scheduler.start();
        
        collectionButtonTapped$.accept(.like)
        
        // Then
        XCTAssertEqual(mockNavigator.presentedSheet, .myCollection(.like))

        // When: 로그아웃 상태면
        mockAppStore.dispatch(.logout)
        scheduler.start()

        collectionButtonTapped$.accept(.like)

        // Then
        XCTAssertEqual(mockNavigator.presentedSheet, .login)
    }


    
    func test_collectionStore_bind_sets_counts_correctly() throws {
        // Given
        let collectionState = CollectionState(
            likedPlaceIds: ["1", "2"],
            bookmarkedPlaceIds: ["3"],
            memoedPlaceIds: ["4", "5", "6"]
        )
        mockCollectionStore.state$.accept(collectionState)
        
        let viewModel = HomeContentViewModel(
            navigator: nil,
            appStore: mockAppStore,
            collectionStore: mockCollectionStore,
            userUsecase: nil,
            authUseCase: nil,
            recentSearchService: nil
        )
        
        let output = viewModel.transform(input: .init(
            collectionButtonTapped$: .empty(),
            placesByTypeButtonTapped$: .empty(),
            placesByCharacterButtonTapped$: .empty(),
            recentSearchCellTapped$: .empty(),
            moreRecentSearchesButtonTapped$: .empty()
        ))
        
        let likeCount = try output.likePlacesCount$.toBlocking().first()
        let bookmarkCount = try output.savePlacesCount$.toBlocking().first()
        let memoCount = try output.memoPlacesCount$.toBlocking().first()

        XCTAssertEqual(likeCount, 2)
        XCTAssertEqual(bookmarkCount, 1)
        XCTAssertEqual(memoCount, 3)
    }
    
    
    func test_recentSearchService_updates_recentSearches$() throws {
        let didChanged$ = PublishRelay<Void>();

        let mockRecent = MockRecentSearchService()
        mockRecent.resultToReturn = .success(RecentSearchFetchResult(items:[
            RecentSearchItem(id:"1", name:"jelusalem",type:"test"),
            RecentSearchItem(id:"2", name:"jelusalem2",type:"test"),
        ], total:2, page:0))

        let viewModel = HomeContentViewModel(
            navigator: nil,
            appStore: mockAppStore,
            collectionStore: mockCollectionStore,
            userUsecase: nil,
            authUseCase: nil,
            recentSearchService: mockRecent
        )
        
        let output = viewModel.transform(input: .init(
            collectionButtonTapped$: .empty(),
            placesByTypeButtonTapped$: .empty(),
            placesByCharacterButtonTapped$: .empty(),
            recentSearchCellTapped$: .empty(),
            moreRecentSearchesButtonTapped$: .empty()
        ))


        // Then
        let items = try output.recentSearches$.toBlocking(timeout: 1).first()
        XCTAssertEqual(items?.count, 2)
        XCTAssertEqual(items?.first?.name, "jelusalem")
    }



}
