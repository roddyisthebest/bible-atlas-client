//
//  PlaceDetailBottomSheetViewModelTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 8/15/25.
//

import XCTest
import RxSwift
import RxRelay
import RxTest
import RxBlocking

@testable import BibleAtlas


final class MockNotificationService2: RxNotificationServiceProtocol {
    private let bus = PublishSubject<Notification>()
    var lastPosted: (name: Notification.Name, object: Any?)?

    func observe(_ name: Notification.Name) -> Observable<Notification> {
        bus.filter { $0.name == name }
    }

    func post(_ name: Notification.Name, object: Any?) {
        lastPosted = (name, object)
        bus.onNext(Notification(name: name, object: object))
    }

    // 테스트 헬퍼
    func triggerRefetch() {
        post(.refetchRequired, object: nil)
    }
    
    func triggerFetchPlaceRequired(placeId: String, prevPlaceId: String?) {
        post(.fetchPlaceRequired, object: ["placeId": placeId, "prevPlaceId": prevPlaceId])
    }

    // 필요하면 정리
    func reset() {
        lastPosted = nil
    }
}




final class PlaceDetailBottomSheetViewModelTests:XCTestCase{
    
        
    var navigator: MockBottomSheetNavigator!
    var placeUsecase: MockPlaceusecase!
    var appStore: MockAppStore!
    var collectionStore: MockCollectionStore!
    var rxNotificationService:MockNotificationService2!
    var schedular: TestScheduler!
    var disposeBag: DisposeBag!
    
    override func setUp() {
        super.setUp()
        
        self.navigator = MockBottomSheetNavigator();
        self.placeUsecase = MockPlaceusecase();
        let appState = AppState(profile: nil, isLoggedIn: false)
        self.appStore = MockAppStore(state: appState);
        self.collectionStore = MockCollectionStore();
        self.rxNotificationService = MockNotificationService2()
        self.schedular = TestScheduler(initialClock: 0);
        self.disposeBag = DisposeBag();
        
    }
    
    func test_viewLoaded_success_setsPlaceAndStopsLoading() {

        let place = Place(id: "test", name: "test", koreanName: "테스트", isModern: true, description: "test",
                          koreanDescription: "테스트", stereo: .child, verse: "", likeCount: 2, types: [])
        placeUsecase.detailResultToReturn = .success(place)

        let vm = PlaceDetailViewModel(
            navigator: navigator,
            placeId: "tuco",
            placeUsecase: placeUsecase,
            appStore: appStore,
            collectionStore: collectionStore,
            notificationService: rxNotificationService
        )

        let viewLoaded$ = PublishRelay<Void>()
        let output = vm.transform(input: .init(
            viewLoaded$: viewLoaded$.asObservable(),
            saveButtonTapped$: .empty(),
            closeButtonTapped$: .empty(),
            backButtonTapped$: .empty(),
            likeButtonTapped$: .empty(),
            placeModificationButtonTapped$: .empty(),
            memoButtonTapped$: .empty(),
            placeCellTapped$: .empty(),
            refetchButtonTapped$: .empty(),
            verseCellTapped$: .empty(),
            moreVerseButtonTapped$: .empty(),
            reportButtonTapped$: .empty()
        ))

        let placeExp = expectation(description: "place set")
        var got: Place?
        output.place$
            .skip(1)
            .take(1)
            .subscribe(onNext: { p in got = p; placeExp.fulfill() })
            .disposed(by: disposeBag)

        let loadingExp = expectation(description: "loading false")
        output.isLoading$
            .skip(1)
            .filter { !$0 }
            .take(1)
            .subscribe(onNext: { _ in loadingExp.fulfill() })
            .disposed(by: disposeBag)

        // when
        viewLoaded$.accept(())

        // then
        wait(for: [placeExp, loadingExp], timeout: 1.0)
        XCTAssertEqual(got?.id, place.id)
    }


    func test_viewLoaded_failure_emitsLoadError_andStopsLoading() {
        placeUsecase.detailResultToReturn = .failure(.clientError("x"))

        let vm = PlaceDetailViewModel(
            navigator: navigator,
            placeId: "tuco",
            placeUsecase: placeUsecase,
            appStore: appStore,
            collectionStore: collectionStore,
            notificationService: rxNotificationService
        )
        
        let viewLoaded$ = PublishRelay<Void>()
        let output = vm.transform(input: .init(
            viewLoaded$: viewLoaded$.asObservable(),
            saveButtonTapped$: .empty(),
            closeButtonTapped$: .empty(),
            backButtonTapped$: .empty(),
            likeButtonTapped$: .empty(),
            placeModificationButtonTapped$: .empty(),
            memoButtonTapped$: .empty(),
            placeCellTapped$: .empty(),
            refetchButtonTapped$: .empty(),
            verseCellTapped$: .empty(),
            moreVerseButtonTapped$: .empty(),
            reportButtonTapped$: .empty()
        ))

        let errorExp = expectation(description: "error emitted")
        var gotErr: NetworkError?
        output.loadError$
            .compactMap { $0 }
            .take(1)
            .subscribe(onNext: { e in gotErr = e; errorExp.fulfill() })
            .disposed(by: disposeBag)

        let loadingExp = expectation(description: "loading false")
        output.isLoading$
            .skip(1)
            .filter { !$0 }
            .take(1)
            .subscribe(onNext: { _ in loadingExp.fulfill() })
            .disposed(by: disposeBag)

        viewLoaded$.accept(())
        wait(for: [errorExp, loadingExp], timeout: 1.0)
        XCTAssertEqual(gotErr, .clientError("x"))
    }

    func test_notification_refetchRequired_triggersRefetch(){
        
        
        let placeDetailExp = expectation(description: "place detail fetch")
        placeUsecase.completedDetailExp = placeDetailExp
        
        let place = Place(id: "test", name: "test", koreanName: "테스트", isModern: true, description: "test", koreanDescription: "테스트", stereo: .child, likeCount: 1, types: [])
        
        placeUsecase.detailResultToReturn = .success(place)
        
        
        let vm = PlaceDetailViewModel(
            navigator: navigator,
            placeId: "tuco",
            placeUsecase: placeUsecase,
            appStore: appStore,
            collectionStore: collectionStore,
            notificationService: rxNotificationService,
            schedular: schedular
        )
        
        let output = vm.transform(input: PlaceDetailViewModel.Input(viewLoaded$: .empty(), saveButtonTapped$: .empty(), closeButtonTapped$: .empty(), backButtonTapped$: .empty(), likeButtonTapped$: .empty(), placeModificationButtonTapped$: .empty(), memoButtonTapped$: .empty(), placeCellTapped$: .empty(), refetchButtonTapped$: .empty(), verseCellTapped$: .empty(), moreVerseButtonTapped$: .empty(), reportButtonTapped$: .empty()))
        
        let placeExp = expectation(description: "place set")
        var got: Place?
        output.place$
            .skip(1)
            .take(1)
            .subscribe(onNext: { place in
                got = place
                placeExp.fulfill() })
            .disposed(by: disposeBag)
        
        let loadingExp = expectation(description: "loading false")
        
        output.isLoading$
            .skip(1)
            .filter { !$0 }
            .take(1)
            .subscribe(onNext: { _ in loadingExp.fulfill() })
            .disposed(by: disposeBag)
        
        rxNotificationService.triggerRefetch()
        schedular.start();
        
        wait(for: [placeDetailExp, placeExp, loadingExp], timeout: 1)
        
        
        XCTAssertEqual(got?.name, place.name)
        
    }
    
    func test_notification_fetchPlaceRequired_updatesPlaceId_setsHasPrev_andRefetches() throws{
        
        let prevPlace = Place(id: "prev-test", name: "prev-test", koreanName: "테스트", isModern: true, description: "test", koreanDescription: "테스트", stereo: .child, likeCount: 1, types: [])
        
        let newPlace = Place(id: "new-test", name: "new-test", koreanName: "테스트", isModern: true, description: "test", koreanDescription: "테스트", stereo: .child, likeCount: 1, types: [])
        
        placeUsecase.detailResultToReturn = .success(prevPlace)
        
        let placeDetailExp = expectation(description: "place detail fetch")
        
        placeUsecase.completedDetailExp = placeDetailExp
        
        let vm = PlaceDetailViewModel(
            navigator: navigator,
            placeId: "tuco",
            placeUsecase: placeUsecase,
            appStore: appStore,
            collectionStore: collectionStore,
            notificationService: rxNotificationService,
            schedular: schedular
        )
        
        let viewLoaded$ = PublishRelay<Void>();
        let output = vm.transform(input: PlaceDetailViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), saveButtonTapped$: .empty(), closeButtonTapped$: .empty(), backButtonTapped$: .empty(), likeButtonTapped$: .empty(), placeModificationButtonTapped$: .empty(), memoButtonTapped$: .empty(), placeCellTapped$: .empty(), refetchButtonTapped$: .empty(), verseCellTapped$: .empty(), moreVerseButtonTapped$: .empty(), reportButtonTapped$: .empty()))
        
        
        viewLoaded$.accept(())
        wait(for: [placeDetailExp], timeout: 1);

        
        rxNotificationService.triggerFetchPlaceRequired(placeId: newPlace.id, prevPlaceId: prevPlace.id)
        schedular.start();
        
        
        let placeDetailExp2 = expectation(description: "place detail fetch2")
        
        placeUsecase.detailResultToReturn = .success(newPlace)
        placeUsecase.completedDetailExp = placeDetailExp2
        
        wait(for: [placeDetailExp2], timeout: 1);

        let hasPrevPlaceId = try output.hasPrevPlaceId$.toBlocking(timeout: 1).first();
        
        XCTAssertEqual(hasPrevPlaceId, true)
        
        
        let placeSetExp = expectation(description: "place reset")
        
        var gotPlace:Place?
        
        output.place$
               .compactMap { $0 }
               .skip(1)
               .take(1)
               .subscribe(onNext: { p in
                   gotPlace = p
                   placeSetExp.fulfill()
               })
               .disposed(by: disposeBag)
        
        wait(for: [placeSetExp], timeout: 1);
        XCTAssertEqual(gotPlace?.id, newPlace.id)

    }

    func test_placeCellTapped_presentsPlaceDetail_withCorrectId(){
        
        let vm = PlaceDetailViewModel(
            navigator: navigator,
            placeId: "tuco",
            placeUsecase: placeUsecase,
            appStore: appStore,
            collectionStore: collectionStore,
            notificationService: rxNotificationService,
            schedular: schedular
        )
        
        let cellTapped$ = PublishRelay<String>();
        
        let _ = vm.transform(input: PlaceDetailViewModel.Input(viewLoaded$: .empty(), saveButtonTapped$: .empty(), closeButtonTapped$: .empty(), backButtonTapped$: .empty(), likeButtonTapped$: .empty(), placeModificationButtonTapped$: .empty(), memoButtonTapped$: .empty(), placeCellTapped$: cellTapped$.asObservable(), refetchButtonTapped$: .empty(), verseCellTapped$: .empty(), moreVerseButtonTapped$: .empty(), reportButtonTapped$: .empty()))
        
        let testPlaceId = "test"
        cellTapped$.accept(testPlaceId)
        
        XCTAssertEqual(navigator.presentedSheet, .placeDetail(testPlaceId))
        
    }
    
    func test_likeButton_notLoggedIn_presentsLogin_andDoesNotCallUsecase(){
        
        let vm = PlaceDetailViewModel(
            navigator: navigator,
            placeId: "tuco",
            placeUsecase: placeUsecase,
            appStore: appStore,
            collectionStore: collectionStore,
            notificationService: rxNotificationService,
            schedular: schedular
        )
        let likeButtonTapped$ = PublishRelay<Void>();
        
        let _ = vm.transform(input: PlaceDetailViewModel.Input(viewLoaded$: .empty(), saveButtonTapped$: .empty(), closeButtonTapped$: .empty(), backButtonTapped$: .empty(), likeButtonTapped$: likeButtonTapped$.asObservable(), placeModificationButtonTapped$: .empty(), memoButtonTapped$: .empty(), placeCellTapped$: .empty(), refetchButtonTapped$: .empty(), verseCellTapped$: .empty(), moreVerseButtonTapped$: .empty(), reportButtonTapped$: .empty()))
        
        likeButtonTapped$.accept(())
        
        XCTAssertEqual(navigator.presentedSheet, .login)
        
    }
    
    
    func test_likeButton_loggedIn_togglesLike_updatesPlace_andCollectionStore(){
        
        let user = User(id: 1, role: .USER, avatar: "as")
        appStore.dispatch(.login(user))
        
        let likeExp = expectation(description: "like toggle");
        placeUsecase.likeExp = likeExp
        
        let placeExp = expectation(description: "place fetch")
        
        placeUsecase.completedDetailExp = placeExp
        
        let place = Place(id: "test", name: "test", koreanName: "테스트", isModern: true, description: "test", koreanDescription: "테스트", stereo: .child, likeCount: 1, types: [])
        
        placeUsecase.detailResultToReturn = .success(place)
        
        placeUsecase.likeResultToReturn = .success(TogglePlaceLikeResponse(liked: true))
        
        let vm = PlaceDetailViewModel(
            navigator: navigator,
            placeId: place.id,
            placeUsecase: placeUsecase,
            appStore: appStore,
            collectionStore: collectionStore,
            notificationService: rxNotificationService,
            schedular: schedular
        )
        
        let viewLoaded$ = PublishRelay<Void>();
        let likeButtonTapped$ = PublishRelay<Void>();
        
        let output = vm.transform(input: PlaceDetailViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), saveButtonTapped$: .empty(), closeButtonTapped$: .empty(), backButtonTapped$: .empty(), likeButtonTapped$: likeButtonTapped$.asObservable(), placeModificationButtonTapped$: .empty(), memoButtonTapped$: .empty(), placeCellTapped$: .empty(), refetchButtonTapped$: .empty(), verseCellTapped$: .empty(), moreVerseButtonTapped$: .empty(), reportButtonTapped$: .empty()))
        
     
        
                
        var got:Place?
        let setPlaceExp = expectation(description: "place set")
        output.place$
            .skip(until:likeButtonTapped$)
            .take(1)
            .subscribe(onNext: {
            place in
                got = place
                setPlaceExp.fulfill()
            
        }).disposed(by: disposeBag)
        
        viewLoaded$.accept(())
        wait(for: [placeExp], timeout: 1);
        
        likeButtonTapped$.accept(())
        wait(for:[likeExp, setPlaceExp], timeout: 1);
        
        XCTAssertEqual(got?.likeCount, 2)
        XCTAssertEqual(collectionStore.lastAction, .like(place.id))
    }
    
    func test_likeButton_failure_emitsInteractionError_andStopsLiking(){
        
        let user = User(id: 1, role: .USER, avatar: "as")
        appStore.dispatch(.login(user))
        
        let likeExp = expectation(description: "like toggle");
        placeUsecase.likeExp = likeExp
        
        let placeExp = expectation(description: "place fetch")
        
        placeUsecase.completedDetailExp = placeExp
        
        let place = Place(id: "test", name: "test", koreanName: "테스트", isModern: true, description: "test", koreanDescription: "테스트", stereo: .child, likeCount: 1, types: [])
        
        placeUsecase.detailResultToReturn = .success(place)
        
        
        placeUsecase.likeResultToReturn = .failure(.clientError("test-error"))
        
        let vm = PlaceDetailViewModel(
            navigator: navigator,
            placeId: place.id,
            placeUsecase: placeUsecase,
            appStore: appStore,
            collectionStore: collectionStore,
            notificationService: rxNotificationService,
            schedular: schedular
        )
        
        let viewLoaded$ = PublishRelay<Void>();
        let likeButtonTapped$ = PublishRelay<Void>();
        
        let output = vm.transform(input: PlaceDetailViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), saveButtonTapped$: .empty(), closeButtonTapped$: .empty(), backButtonTapped$: .empty(), likeButtonTapped$: likeButtonTapped$.asObservable(), placeModificationButtonTapped$: .empty(), memoButtonTapped$: .empty(), placeCellTapped$: .empty(), refetchButtonTapped$: .empty(), verseCellTapped$: .empty(), moreVerseButtonTapped$: .empty(), reportButtonTapped$: .empty()))
        
        
        let likingDoneExp = expectation(description: "isLiking turned back to false")
        
        output.isLiking$
            .skip(1)
            .filter { !$0 }
            .take(1)
            .subscribe(onNext: { _ in likingDoneExp.fulfill() })
            .disposed(by: disposeBag)
        
        
        
        let errorExp = expectation(description: "error emitted")
        var gotErr:NetworkError?
        
        output.interactionError$
            .compactMap{$0}
            .take(1)
            .subscribe(onNext:{
                error in
                gotErr = error
                errorExp.fulfill()
            })
            .disposed(by: disposeBag)
        
        
        viewLoaded$.accept(())
        wait(for: [placeExp], timeout: 1);
        
        likeButtonTapped$.accept(())
 
        wait(for: [likeExp, likingDoneExp, errorExp], timeout: 1.0)
    
        XCTAssertEqual(gotErr, .clientError("test-error"))
    
    }
    
    func test_saveButton_notLoggedIn_presentsLogin_andDoesNotCallUsecase() {
       
        
        let vm = PlaceDetailViewModel(
            navigator: navigator,
            placeId: "tuco",
            placeUsecase: placeUsecase,
            appStore: appStore,
            collectionStore: collectionStore,
            notificationService: rxNotificationService
        )
        
        let saveButtonTapped$ = PublishRelay<Void>()
        
        let output = vm.transform(input: .init(
            viewLoaded$: .empty(),
            saveButtonTapped$: saveButtonTapped$.asObservable(),
            closeButtonTapped$: .empty(),
            backButtonTapped$: .empty(),
            likeButtonTapped$: .empty(),
            placeModificationButtonTapped$: .empty(),
            memoButtonTapped$: .empty(),
            placeCellTapped$: .empty(),
            refetchButtonTapped$: .empty(),
            verseCellTapped$: .empty(), 
            moreVerseButtonTapped$: .empty(),
            reportButtonTapped$: .empty()
        ))

    
        let noSavingToggle = expectation(description: "no isSaving toggle")
        noSavingToggle.isInverted = true
        output.isSaving$
            .skip(until:saveButtonTapped$)
            .subscribe(onNext: { _ in noSavingToggle.fulfill() })
            .disposed(by: disposeBag)

  

        saveButtonTapped$.accept(())


        XCTAssertEqual(navigator.presentedSheet, .login)
        wait(for: [noSavingToggle], timeout: 0.2)
     
        
    }
    
    
    func test_saveButton_loggedIn_togglesSave_updatesPlace_andCollectionStore(){
        
        let user = User(id: 1, role: .USER, avatar: "as")
        appStore.dispatch(.login(user))
        
        let saveExp = expectation(description: "save toggle");
        placeUsecase.saveExp = saveExp
        
        let placeExp = expectation(description: "place fetch")
        
        placeUsecase.completedDetailExp = placeExp
        
        let place = Place(id: "test", name: "test", koreanName: "테스트", isModern: true, description: "test", koreanDescription: "테스트", stereo: .child, likeCount: 1, types: [], isSaved: false)
        
        placeUsecase.detailResultToReturn = .success(place)
        
        placeUsecase.saveResultToReturn = .success(TogglePlaceSaveResponse(saved: true))
        
        let vm = PlaceDetailViewModel(
            navigator: navigator,
            placeId: place.id,
            placeUsecase: placeUsecase,
            appStore: appStore,
            collectionStore: collectionStore,
            notificationService: rxNotificationService,
            schedular: schedular
        )
        
        let viewLoaded$ = PublishRelay<Void>();
        let saveButtonTapped$ = PublishRelay<Void>();
        
        let output = vm.transform(input: PlaceDetailViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), saveButtonTapped$: saveButtonTapped$.asObservable(), closeButtonTapped$: .empty(), backButtonTapped$: .empty(), likeButtonTapped$: .empty(), placeModificationButtonTapped$: .empty(), memoButtonTapped$: .empty(), placeCellTapped$: .empty(), refetchButtonTapped$: .empty(), verseCellTapped$: .empty(), moreVerseButtonTapped$: .empty(), reportButtonTapped$: .empty()))
        
        
        var got:Place?
        let setPlaceExp = expectation(description: "place set")
        
        output.place$
            .skip(until:saveButtonTapped$)
            .take(1)
            .subscribe(onNext: {
            place in
                got = place
                setPlaceExp.fulfill()
            
        }).disposed(by: disposeBag)
        
        
        
        
        
        viewLoaded$.accept(())
        wait(for: [placeExp], timeout: 1);
        
        saveButtonTapped$.accept(())
        wait(for:[saveExp, setPlaceExp], timeout: 1);
        
        XCTAssertEqual(got?.isSaved, true)
        XCTAssertEqual(collectionStore.lastAction, .bookmark(place.id))
        
    }

    
    
    func test_saveButton_failure_emitsInteractionError_andStopsSaving(){
        
        let user = User(id: 1, role: .USER, avatar: "as")
        appStore.dispatch(.login(user))
        
        let saveExp = expectation(description: "save toggle");
        placeUsecase.saveExp = saveExp
        
        let placeExp = expectation(description: "place fetch")
        
        placeUsecase.completedDetailExp = placeExp
        
        let place = Place(id: "test", name: "test", koreanName: "테스트", isModern: true, description: "test", koreanDescription: "테스트", stereo: .child, likeCount: 1, types: [], isSaved: false)
        
        placeUsecase.detailResultToReturn = .success(place)
        
        placeUsecase.saveResultToReturn = .failure(.clientError("test-error"))
        
        let vm = PlaceDetailViewModel(
            navigator: navigator,
            placeId: place.id,
            placeUsecase: placeUsecase,
            appStore: appStore,
            collectionStore: collectionStore,
            notificationService: rxNotificationService,
            schedular: schedular
        )
        
        let viewLoaded$ = PublishRelay<Void>();
        let saveButtonTapped$ = PublishRelay<Void>();
        
        let output = vm.transform(input: PlaceDetailViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), saveButtonTapped$: saveButtonTapped$.asObservable(), closeButtonTapped$: .empty(), backButtonTapped$: .empty(), likeButtonTapped$: .empty(), placeModificationButtonTapped$: .empty(), memoButtonTapped$: .empty(), placeCellTapped$: .empty(), refetchButtonTapped$: .empty(), verseCellTapped$: .empty(), moreVerseButtonTapped$: .empty(), reportButtonTapped$: .empty()))
        
        
        var gotErr:NetworkError?
        let errorExp = expectation(description: "error set")
        
        output.interactionError$
            .skip(until:saveButtonTapped$)
            .take(1)
            .subscribe(onNext: {
            error in
                gotErr = error
                errorExp.fulfill()
            
        }).disposed(by: disposeBag)
        
        
        let savingDoneExp = expectation(description: "isSaving turned back to false")
        
        output.isSaving$
            .skip(1)
            .filter { !$0 }
            .take(1)
            .subscribe(onNext: { _ in savingDoneExp.fulfill() })
            .disposed(by: disposeBag)
        
        
        
        viewLoaded$.accept(())
        wait(for: [placeExp], timeout: 1);
        
        saveButtonTapped$.accept(())
        wait(for:[saveExp, errorExp, savingDoneExp ], timeout: 1);
        
        XCTAssertEqual(gotErr, .clientError("test-error"))
    }
    
    func test_bindAppStore_updates_isLoggedIn_andProfile(){
        
        let user = User(id: 1, role: .USER, avatar: "as")
        appStore.dispatch(.login(user))
        
        let vm = PlaceDetailViewModel(
            navigator: navigator,
            placeId: "tuco",
            placeUsecase: placeUsecase,
            appStore: appStore,
            collectionStore: collectionStore,
            notificationService: rxNotificationService,
            schedular: schedular
        )
        
        let output = vm.transform(input: PlaceDetailViewModel.Input(viewLoaded$: .empty(), saveButtonTapped$: .empty(), closeButtonTapped$: .empty(), backButtonTapped$: .empty(), likeButtonTapped$: .empty(), placeModificationButtonTapped$: .empty(), memoButtonTapped$: .empty(), placeCellTapped$: .empty(), refetchButtonTapped$: .empty(), verseCellTapped$: .empty(), moreVerseButtonTapped$: .empty(), reportButtonTapped$: .empty()))
        
        let isLoggedInExp = expectation(description: "isLoggedIn set")
        
        var gotIsLoggedIn:Bool?
        output.isLoggedIn$
            .take(1)
            .subscribe(onNext:{
                isLoggedIn in
                gotIsLoggedIn = isLoggedIn
                isLoggedInExp.fulfill();
            }).disposed(by: disposeBag)
        
        
        let profileExp = expectation(description: "profile set")
        
        var gotProfile:User?
        output.profile$
            .take(1)
            .subscribe(onNext:{
                profile in
                gotProfile = profile
                profileExp.fulfill();
            }).disposed(by: disposeBag)
        
        
        wait(for: [isLoggedInExp, profileExp], timeout: 1);
        
        XCTAssertEqual(gotIsLoggedIn, true)
        XCTAssertEqual(gotProfile?.name, user.name)

        
    }
    
    
    func test_currentPlace_returnsLatestPlace(){
      
        
        
        let placeExp = expectation(description: "place fetch")
        
        placeUsecase.completedDetailExp = placeExp
        
        let place = Place(id: "test", name: "test", koreanName: "테스트", isModern: true, description: "test", koreanDescription: "테스트", stereo: .child, likeCount: 1, types: [], isSaved: false)
        
        placeUsecase.detailResultToReturn = .success(place)
    
        let vm = PlaceDetailViewModel(
            navigator: navigator,
            placeId: place.id,
            placeUsecase: placeUsecase,
            appStore: appStore,
            collectionStore: collectionStore,
            notificationService: rxNotificationService,
            schedular: schedular
        )
        
        let viewLoaded$ = PublishRelay<Void>();

        
        let output = vm.transform(input: PlaceDetailViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), saveButtonTapped$: .empty(), closeButtonTapped$: .empty(), backButtonTapped$: .empty(), likeButtonTapped$: .empty(), placeModificationButtonTapped$: .empty(), memoButtonTapped$: .empty(), placeCellTapped$: .empty(), refetchButtonTapped$: .empty(), verseCellTapped$: .empty(), moreVerseButtonTapped$: .empty(), reportButtonTapped$: .empty()))
        
        
        let placeSetExp = expectation(description: "place set")
        
        var got:Place?
        output.place$
            .skip(1)
            .subscribe(onNext:{ place in
                got = place
                placeSetExp.fulfill()
            }).disposed(by: disposeBag)
        
        
        
        viewLoaded$.accept(())
        wait(for: [placeExp, placeSetExp], timeout: 1);
        
        XCTAssertEqual(got?.id, vm.currentPlace?.id)
    }
    
    
    func test_hasPrevPlaceId_updatesBasedOnNotificationPayload() {
        
        let vm = PlaceDetailViewModel(
            navigator: navigator,
            placeId: "tuco",
            placeUsecase: placeUsecase,
            appStore: appStore,
            collectionStore: collectionStore,
            notificationService: rxNotificationService,
            schedular: schedular
        )
            
        
        var gotValues: [Bool] = []
        let exp = expectation(description: "values received")
        exp.expectedFulfillmentCount = 2
        
        let output = vm.transform(input: PlaceDetailViewModel.Input(viewLoaded$: .empty(), saveButtonTapped$: .empty(), closeButtonTapped$: .empty(), backButtonTapped$: .empty(), likeButtonTapped$: .empty(), placeModificationButtonTapped$: .empty(), memoButtonTapped$: .empty(), placeCellTapped$: .empty(), refetchButtonTapped$: .empty(), verseCellTapped$: .empty(), moreVerseButtonTapped$: .empty(), reportButtonTapped$: .empty()))
        
        output.hasPrevPlaceId$
            .skip(1)
            .take(2)
            .subscribe(onNext: { v in
                   gotValues.append(v)
                   exp.fulfill()
               })
            .disposed(by: disposeBag)

        rxNotificationService.triggerFetchPlaceRequired(placeId: "new-1", prevPlaceId: nil)
        
        rxNotificationService.triggerFetchPlaceRequired(placeId: "new-2", prevPlaceId: "prev-xxx")
        
        schedular.start()

        wait(for: [exp], timeout: 1)
        XCTAssertEqual(gotValues, [false, true])
    }

    
    func test_viewLoaded_success_emitsPlaceAndRestBiblesCount() {

        let place = Place(id: "test", name: "test", koreanName: "테스트", isModern: true, description: "test",
                          koreanDescription: "테스트", stereo: .child, verse: "", likeCount: 2, types: [])
        placeUsecase.parsedBible = [
            Bible(bookName: .Acts, verses: []),
            Bible(bookName: .Amos, verses: []),
            Bible(bookName: .Chr1, verses: []),
            Bible(bookName: .Col, verses: []),
            Bible(bookName: .Chr2, verses: [])
        ]
        placeUsecase.detailResultToReturn = .success(place)

        let vm = PlaceDetailViewModel(
            navigator: navigator,
            placeId: "tuco",
            placeUsecase: placeUsecase,
            appStore: appStore,
            collectionStore: collectionStore,
            notificationService: rxNotificationService
        )

        let viewLoaded$ = PublishRelay<Void>()
        let output = vm.transform(input: .init(
            viewLoaded$: viewLoaded$.asObservable(),
            saveButtonTapped$: .empty(),
            closeButtonTapped$: .empty(),
            backButtonTapped$: .empty(),
            likeButtonTapped$: .empty(),
            placeModificationButtonTapped$: .empty(),
            memoButtonTapped$: .empty(),
            placeCellTapped$: .empty(),
            refetchButtonTapped$: .empty(),
            verseCellTapped$: .empty(),
            moreVerseButtonTapped$: .empty(),
            reportButtonTapped$: .empty()
        ))

        let placeExp = expectation(description: "place set")
        var gotPlace: Place?
        output.place$
            .skip(1)
            .take(1)
            .subscribe(onNext: { p in gotPlace = p; placeExp.fulfill() })
            .disposed(by: disposeBag)

        let biblesExp = expectation(description: "bibles set")
        var gotBibles: ([Bible], Int)?
        
        output.bibles$.skip(1).take(1).subscribe(onNext:{
            bibles in
            gotBibles = bibles
            biblesExp.fulfill()
        }).disposed(by: disposeBag)
        
        // when
        viewLoaded$.accept(())

        // then
        wait(for: [placeExp, biblesExp], timeout: 1.0)
        XCTAssertEqual(gotPlace?.id, place.id)
        XCTAssertEqual(gotBibles?.1, 2)
    }
    
    
    
}
