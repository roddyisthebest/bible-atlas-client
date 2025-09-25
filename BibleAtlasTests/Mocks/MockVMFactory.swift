//
//  MockVMFactory.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/25/25.
//

import UIKit
import RxSwift
import RxRelay
@testable import BibleAtlas

final class MockVMFactory: VMFactoryProtocol {
    // 호출 기록(간단)
    private(set) var made: [String] = []

    // 필요한 것만 구현, 나머지는 fatalError로 명시
    func makeHomeBottomSheetVM() -> HomeBottomSheetViewModelProtocol {
        made.append("homeVM")
        return StubHomeBottomSheetVM()
    }

    func makeHomeContentVM() -> HomeContentViewModelProtocol {
        made.append("homeContentVM")
        return MockHomeContentViewModel()
    }

    func makeSearchResultVM(keyword$: Observable<String>, isSearchingMode$: Observable<Bool>, cancelButtonTapped$: Observable<Void>) -> SearchResultViewModelProtocol {
        made.append("searchResultVM")
        return MockSearchResultViewModel()
    }

    func makeSearchReadyVM() -> SearchReadyViewModelProtocol {
        made.append("searchReadyVM")
        return MockSearchReadyViewModel()
    }

    func makePlaceDetailBottomSheetVM(placeId: String) -> PlaceDetailViewModelProtocol {
        made.append("placeDetailVM(\(placeId))")
        return MockPlaceDetailViewModel()
    }

    func makeLoginBottomSheetVM() -> LoginBottomSheetViewModelProtocol {
        made.append("loginVM")
        fatalError()
    }

    // 이하 테스트에 불필요 → 명시적 중단
    func makeSearchBottomSheetVM() -> SearchBottomSheetViewModelProtocol { fatalError() }
    func makeMyCollectionBottomSheetVM(filter: PlaceFilter) -> MyCollectionBottomSheetViewModelProtocol { fatalError() }
    func makeMemoBottomSheetVM(placeId: String) -> MemoBottomSheetViewModelProtocol { fatalError() }
    func makePlaceModificationBottomSheerVM(placeId: String) -> PlaceModificationBottomSheetViewModelProtocol { fatalError() }
    func makePlaceTypesBottomSheetVM() -> PlaceTypesBottomSheetViewModelProtocol { fatalError() }
    func makePlaceCharactersBottomSheetVM() -> PlaceCharactersBottomSheetViewModelProtocol { fatalError() }
    func makeBiblesBottomSheetVM() -> BiblesBottomSheetViewModelProtocol { fatalError() }
    func makePlacesByTypeBottomSheetVM(placeTypeName: PlaceTypeName) -> PlacesByTypeBottomSheetViewModelProtocol { fatalError() }
    func makePlacesByCharacterBottomSheetVM(character: String) -> PlacesByCharacterBottomSheetViewModelProtocol { fatalError() }
    func makePlacesByBibleBottomSheetVM(bible: BibleBook) -> PlacesByBibleBottomSheetViewModelProtocol { fatalError() }
    func makeBibleVerseDetailBottomSheetVM(bibleBook: BibleBook, keyword: String) -> BibleVerseDetailBottomSheetViewModelProtocol { fatalError() }
    func makeRecentSearchesBottomSheetVM() -> RecentSearchesBottomSheetViewModelProtocol { fatalError() }
    func makePopularPlacesBottomSheetVM() -> PopularPlacesBottomSheetViewModelProtocol { fatalError() }
    func makeMyPageBottomSheetVM() -> MyPageBottomSheetViewModelProtocol { fatalError() }
    func makeAccountManagementBottomSheetVM() -> AccountManagementBottomSheetViewModelProtocol { fatalError() }
    func makeReportBottomSheetVM(placeId: String, reportType: PlaceReportType) -> ReportBottomSheetViewModelProtocol { fatalError() }
    func makeMainVM() -> MainViewModelProtocol { fatalError() }

    func configure(navigator: BottomSheetNavigator, appCoordinator: AppCoordinatorProtocol) {}
}

// === Stub VMs (최소 구현) ===
// 각 프로토콜이 요구하는 속성/메서드를 "크래시 안 나게"만 채움

final class StubHomeBottomSheetVM: HomeBottomSheetViewModelProtocol {
    let isSearchingMode$ = BehaviorRelay<Bool>(value: false)
    let keyword$ = BehaviorRelay<String>(value: "")
    let cancelButtonTapped$ = PublishRelay<Void>()
    func transform(input: HomeBottomSheetViewModel.Input) -> HomeBottomSheetViewModel.Output {
        return .init(
            profile$: .just(nil),
            isLoggedIn$: .just(false),
            screenMode$: Observable.just(.home),
            keyword$: keyword$,
            keywordText$: keyword$.asDriver(),
            isSearchingMode$: isSearchingMode$.asObservable()
        )
    }
}




