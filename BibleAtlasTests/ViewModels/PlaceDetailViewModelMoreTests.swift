import XCTest
import RxSwift
import RxRelay
import RxBlocking
import RxTest

@testable import BibleAtlas

final class PlaceDetailViewModelMoreTests: XCTestCase {
    var navigator: MockBottomSheetNavigator!
    var placeUsecase: MockPlaceusecase!
    var appStore: MockAppStore!
    var collectionStore: MockCollectionStore!
    var rxNotificationService: MockNotificationService2!
    var schedular: TestScheduler!
    var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        navigator = MockBottomSheetNavigator()
        placeUsecase = MockPlaceusecase()
        appStore = MockAppStore(state: AppState(profile: nil, isLoggedIn: false))
        collectionStore = MockCollectionStore()
        rxNotificationService = MockNotificationService2()
        schedular = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()
    }

    func test_likeButton_loggedIn_unlike_decrementsCount_andDispatchesUnlike() {
        // given logged in and an already liked place
        let user = User(id: 42, role: .USER, avatar: "a")
        appStore.dispatch(.login(user))

        let place = Place(id: "p1", name: "P", koreanName: "피", isModern: false, description: "", koreanDescription: "", stereo: .child, likeCount: 2, types: [], isLiked: true)
        placeUsecase.detailResultToReturn = .success(place)
        placeUsecase.likeResultToReturn = .success(TogglePlaceLikeResponse(liked: false))

        let firstFetch = expectation(description: "first fetch")
        placeUsecase.completedDetailExp = firstFetch

        let vm = PlaceDetailViewModel(
            navigator: navigator,
            placeId: place.id,
            placeUsecase: placeUsecase,
            appStore: appStore,
            collectionStore: collectionStore,
            notificationService: rxNotificationService,
            schedular: schedular
        )

        let viewLoaded$ = PublishRelay<Void>()
        let like$ = PublishRelay<Void>()
        let output = vm.transform(input: .init(
            viewLoaded$: viewLoaded$.asObservable(),
            saveButtonTapped$: .empty(),
            closeButtonTapped$: .empty(),
            backButtonTapped$: .empty(),
            likeButtonTapped$: like$.asObservable(),
            placeModificationButtonTapped$: .empty(),
            memoButtonTapped$: .empty(),
            placeCellTapped$: .empty(),
            refetchButtonTapped$: .empty(),
            verseCellTapped$: .empty(),
            moreVerseButtonTapped$: .empty(),
            reportButtonTapped$: .empty(),
            shareButtonTapped$: .empty()
        ))

        viewLoaded$.accept(())
        wait(for: [firstFetch], timeout: 1.0)

        var updated: Place?
        let updatedExp = expectation(description: "place updated after unlike")
        output.place$
            .skip(until: like$)
            .take(1)
            .subscribe(onNext: { p in
                updated = p
                updatedExp.fulfill()
            })
            .disposed(by: disposeBag)

        like$.accept(())
        wait(for: [updatedExp], timeout: 1.0)

        XCTAssertEqual(updated?.isLiked, false)
        XCTAssertEqual(updated?.likeCount, 1)
        XCTAssertEqual(collectionStore.lastAction, .unlike(place.id))
    }

    func test_saveButton_loggedIn_unbookmark_updatesPlace_andDispatchesUnbookmark() {
        // given
        let user = User(id: 1, role: .USER, avatar: "a")
        appStore.dispatch(.login(user))

        let place = Place(id: "p2", name: "Q", koreanName: "큐", isModern: false, description: "", koreanDescription: "", stereo: .child, likeCount: 0, types: [], isSaved: true)
        placeUsecase.detailResultToReturn = .success(place)
        placeUsecase.saveResultToReturn = .success(TogglePlaceSaveResponse(saved: false))

        let firstFetch = expectation(description: "first fetch")
        placeUsecase.completedDetailExp = firstFetch

        let vm = PlaceDetailViewModel(
            navigator: navigator,
            placeId: place.id,
            placeUsecase: placeUsecase,
            appStore: appStore,
            collectionStore: collectionStore,
            notificationService: rxNotificationService,
            schedular: schedular
        )

        let viewLoaded$ = PublishRelay<Void>()
        let save$ = PublishRelay<Void>()
        let output = vm.transform(input: .init(
            viewLoaded$: viewLoaded$.asObservable(),
            saveButtonTapped$: save$.asObservable(),
            closeButtonTapped$: .empty(),
            backButtonTapped$: .empty(),
            likeButtonTapped$: .empty(),
            placeModificationButtonTapped$: .empty(),
            memoButtonTapped$: .empty(),
            placeCellTapped$: .empty(),
            refetchButtonTapped$: .empty(),
            verseCellTapped$: .empty(),
            moreVerseButtonTapped$: .empty(),
            reportButtonTapped$: .empty(),
            shareButtonTapped$: .empty()
        ))

        viewLoaded$.accept(())
        wait(for: [firstFetch], timeout: 1.0)

        var updated: Place?
        let updatedExp = expectation(description: "place updated after unbookmark")
        output.place$
            .skip(until: save$)
            .take(1)
            .subscribe(onNext: { p in
                updated = p
                updatedExp.fulfill()
            })
            .disposed(by: disposeBag)

        save$.accept(())
        wait(for: [updatedExp], timeout: 1.0)

        XCTAssertEqual(updated?.isSaved, false)
        XCTAssertEqual(collectionStore.lastAction, .unbookmark(place.id))
    }

    func test_refetchButtonTapped_triggersReload_andEmitsPlace() {
        let place = Place(id: "p3", name: "R", koreanName: "알", isModern: false, description: "", koreanDescription: "", stereo: .child, likeCount: 0, types: [])
        placeUsecase.detailResultToReturn = .success(place)

        let vm = PlaceDetailViewModel(
            navigator: navigator,
            placeId: place.id,
            placeUsecase: placeUsecase,
            appStore: appStore,
            collectionStore: collectionStore,
            notificationService: rxNotificationService
        )

        let refetch$ = PublishRelay<Void>()
        let output = vm.transform(input: .init(
            viewLoaded$: .empty(),
            saveButtonTapped$: .empty(),
            closeButtonTapped$: .empty(),
            backButtonTapped$: .empty(),
            likeButtonTapped$: .empty(),
            placeModificationButtonTapped$: .empty(),
            memoButtonTapped$: .empty(),
            placeCellTapped$: .empty(),
            refetchButtonTapped$: refetch$.asObservable(),
            verseCellTapped$: .empty(),
            moreVerseButtonTapped$: .empty(),
            reportButtonTapped$: .empty(),
            shareButtonTapped$: .empty()
        ))

        let exp = expectation(description: "place emitted on refetch")
        var got: Place?
        output.place$
            .skip(1)
            .take(1)
            .subscribe(onNext: { p in got = p; exp.fulfill() })
            .disposed(by: disposeBag)

        refetch$.accept(())

        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(got?.id, place.id)
    }
}
