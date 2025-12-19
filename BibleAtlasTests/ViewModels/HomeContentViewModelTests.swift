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
                print("login-user")
                state$.accept(AppState(profile:user, isLoggedIn: true))
                print("login-user-all")
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
    
    var placesExp: XCTestExpectation?

    var myCollectionPlaceIdsResultToReturn: Result<MyCollectionPlaceIds, NetworkError>?
    
    var profileResultToReturn: Result<User, NetworkError>?
    
    var placesResultToReturn: Result<ListResponse<Place>, NetworkError>?

    var placesResultsQueue: [Result<ListResponse<Place>, NetworkError>] = []
    
    var getPlacesCallCount = 0
    
    func getPlaces(limit: Int?, page: Int?, filter: PlaceFilter?) async -> Result<ListResponse<Place>, NetworkError> {
          getPlacesCallCount += 1
          
          if !placesResultsQueue.isEmpty {
              return placesResultsQueue.removeFirst()
          }
          return placesResultToReturn ?? .failure(.clientError("not-set"))
      }

      func getProfile() async -> Result<User, NetworkError> {
          return profileResultToReturn ?? .failure(.clientError("not-set"))
      }

      func getMyCollectionPlaceIds() async -> Result<MyCollectionPlaceIds, NetworkError> {
          return myCollectionPlaceIdsResultToReturn ?? .failure(.clientError("not-set"))
      }
    
}


final class MockRecentSearchService: RecentSearchServiceProtocol {
    
    var resultToReturn: Result<RecentSearchFetchResult, RecentSearchError>?
    var resultExp:XCTestExpectation?
    var savedPlaces:[Place] = []
    func fetch(limit: Int, page: Int?) -> Result<RecentSearchFetchResult, RecentSearchError> {
        defer{
            resultExp?.fulfill()
        }
        fetchCalled = true
        return resultToReturn ?? .success(RecentSearchFetchResult(items:[], total:0, page:0))
    }
    
    func save(_ place: BibleAtlas.Place) -> Result<Void, BibleAtlas.RecentSearchError> {
        savedPlaces.append(place)
        return saveResultToReturn ?? .success(())
    }
    
    func delete(id: String) -> Result<Void, BibleAtlas.RecentSearchError> {
        .success(())
    }
    
    
    var clearAllResultToReturn: Result<Void, RecentSearchError>?

    func clearAll() -> Result<Void, BibleAtlas.RecentSearchError> {
        return clearAllResultToReturn ?? .failure(.unknown)
    }
    
    private let didChangeSubject$ = PublishSubject<Void>()
    public var didChanged$: Observable<Void> {
        didChangeSubject$.asObservable()
    }

    var fetchCalled = false

    var saveResultToReturn: Result<Void,RecentSearchError>?
    
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
    var notificationService: MockNotificationService!

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
            schedular: scheduler,              // 이건 ViewModel 내부 다른 테스트용에서 쓰고 있으면 그냥 둬도 됨
            notificationService: notificationService
        )

        let output = viewModel.transform(input: .init(
            collectionButtonTapped$: .empty(),
            placesByTypeButtonTapped$: .empty(),
            placesByCharacterButtonTapped$: .empty(),
            placesByBibleButtonTapped$: .empty(),
            recentSearchCellTapped$: .empty(),
            moreRecentSearchesButtonTapped$: .empty(),
            reportButtonTapped$: .empty()
        ))

        let loggedInExpectation = expectation(description: "isLoggedIn updated")
        let profileExpectation = expectation(description: "profile updated")

        var lastIsLoggedIn: Bool?
        var lastProfile: User?


        output.isLoggedIn$
            .skip(1) // 초기값(false) 스킵하고 로그인 후 값만 보고 싶다면
            .subscribe(onNext: { value in
                lastIsLoggedIn = value
                loggedInExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        output.profile$
            .compactMap{$0}
            .take(1)
            .subscribe(onNext: { profile in
                lastProfile = profile
                profileExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        // When
        mockAppStore.dispatch(.login(expectedUser))
        
        // Then
        wait(for: [loggedInExpectation, profileExpectation], timeout: 1.0)
        
        XCTAssertEqual(lastIsLoggedIn, true)
        XCTAssertEqual(lastProfile?.name, "test")
        XCTAssertEqual(
            mockCollectionStore.lastAction,
            .initialize(MyCollectionPlaceIds(liked: [], bookmarked: [], memoed: []))
        )
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
            schedular: scheduler,
            notificationService: notificationService
        )
        
        let collectionButtonTapped$ = PublishRelay<PlaceFilter>();

        let input = HomeContentViewModel.Input(
            collectionButtonTapped$: collectionButtonTapped$.asObservable(),
            placesByTypeButtonTapped$: .empty(),
            placesByCharacterButtonTapped$: .empty(), 
            placesByBibleButtonTapped$: .empty(),
            recentSearchCellTapped$: .empty(),
            moreRecentSearchesButtonTapped$: .empty(),
            reportButtonTapped$: .empty()
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
            recentSearchService: nil,
            notificationService: nil
        )
        
        let output = viewModel.transform(input: .init(
            collectionButtonTapped$: .empty(),
            placesByTypeButtonTapped$: .empty(),
            placesByCharacterButtonTapped$: .empty(), 
            placesByBibleButtonTapped$: .empty(),
            recentSearchCellTapped$: .empty(),
            moreRecentSearchesButtonTapped$: .empty(), 
            reportButtonTapped$: .empty()
        ))
        
        let likeCount = try output.likePlacesCount$.toBlocking().first()
        let bookmarkCount = try output.savePlacesCount$.toBlocking().first()
        let memoCount = try output.memoPlacesCount$.toBlocking().first()

        XCTAssertEqual(likeCount, 2)
        XCTAssertEqual(bookmarkCount, 1)
        XCTAssertEqual(memoCount, 3)
    }
    
    
    func test_recentSearchService_updates_recentSearches$() throws {

        let mockRecent = MockRecentSearchService()
        mockRecent.resultToReturn = .success(RecentSearchFetchResult(items:[
            RecentSearchItem(id:"1", name:"jelusalem", koreanName: "테스트", type:"test"),
            RecentSearchItem(id:"2", name:"jelusalem2", koreanName: "테스트", type:"test"),
        ], total:2, page:0))

        let viewModel = HomeContentViewModel(
            navigator: nil,
            appStore: mockAppStore,
            collectionStore: mockCollectionStore,
            userUsecase: nil,
            authUseCase: nil,
            recentSearchService: mockRecent,
            notificationService: notificationService
        )
        
        let output = viewModel.transform(input: .init(
            collectionButtonTapped$: .empty(),
            placesByTypeButtonTapped$: .empty(),
            placesByCharacterButtonTapped$: .empty(), 
            placesByBibleButtonTapped$: .empty(),
            recentSearchCellTapped$: .empty(),
            moreRecentSearchesButtonTapped$: .empty(), 
            reportButtonTapped$: .empty()
        ))


        // Then
        let items = try output.recentSearches$.toBlocking(timeout: 1).first()
        XCTAssertEqual(items?.count, 2)
        XCTAssertEqual(items?.first?.name, "jelusalem")
    }

}
