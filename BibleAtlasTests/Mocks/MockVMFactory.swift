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

class MockVMFactory: VMFactoryProtocol {
 
    
    
    func makeBibleVerseDetailBottomSheetVM(bibleBook: BibleAtlas.BibleBook, keyword: String, placeName: String?) -> BibleAtlas.BibleVerseDetailBottomSheetViewModelProtocol {
        made.append("bibleVerseDetailBottomSheetVM")
        return MockBibleVerseDetailBottomSheetViewModel()
    }
    
    func makePlaceReportBottomSheetVM(placeId: String, reportType: BibleAtlas.PlaceReportType) -> BibleAtlas.PlaceReportBottomSheetViewModelProtocol {
        made.append("placeReportBottomSheetVM")
        return MockPlaceReportBottomSheetViewModelForVC()
    }
    
    func makeReportBottomSheetVM() -> BibleAtlas.ReportBottomSheetViewModelProtocol {
        made.append("reportBottomSheetVM")
        return MockReportBottomSheetViewModel()

    }
    
    func makeBibleBookVerseListBottomSheetVM(placeId: String, bibleBook: BibleAtlas.BibleBook?) -> BibleAtlas.BibleBookVerseListBottomSheetViewModelProtocol {
        made.append("bibleBookVerseListBottomSheetVM")
        return MockBibleBookVerseListBottomSheetViewModel()

    }
    
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
        return MockLoginBottomSheetViewModel()
    }

    // 이하 테스트에 불필요 → 명시적 중단
    func makeMyCollectionBottomSheetVM(filter: PlaceFilter) -> MyCollectionBottomSheetViewModelProtocol {
            made.append("myCollectionVM")
            return MockMyCollectionBottomSheetViewModel()
    }
    func makeMemoBottomSheetVM(placeId: String) -> MemoBottomSheetViewModelProtocol {
            made.append("memoVM(\(placeId))")
            return MockMemoBottomSheetViewModel()
        }
    
    func makePlaceModificationBottomSheetVM(placeId: String) -> PlaceModificationBottomSheetViewModelProtocol {
            made.append("placeModificationVM(\(placeId))")
            return MockPlaceModificationBottomSheetViewModel()
        }
        
        func makePlaceTypesBottomSheetVM() -> PlaceTypesBottomSheetViewModelProtocol {
            made.append("placeTypesVM")
            return MockPlaceTypesBottomSheetViewModel()
        }
        
        func makePlaceCharactersBottomSheetVM() -> PlaceCharactersBottomSheetViewModelProtocol {
            made.append("placeCharactersVM")
            return MockPlaceCharactersBottomSheetViewModel()
        }
        
        func makeBiblesBottomSheetVM() -> BiblesBottomSheetViewModelProtocol {
            made.append("biblesVM")
            return MockBiblesBottomSheetViewModel()
        }
        
        func makePlacesByTypeBottomSheetVM(placeTypeName: PlaceTypeName) -> PlacesByTypeBottomSheetViewModelProtocol {
            made.append("placesByTypeVM")
            return MockPlacesByTypeBottomSheetViewModel()
        }
        
        func makePlacesByCharacterBottomSheetVM(character: String) -> PlacesByCharacterBottomSheetViewModelProtocol {
            made.append("placesByCharacterVM(\(character))")
            return MockPlacesByCharacterBottomSheetViewModel()
        }
        
        func makePlacesByBibleBottomSheetVM(bible: BibleBook) -> PlacesByBibleBottomSheetViewModelProtocol {
            made.append("placesByBibleVM")
            return MockPlacesByBibleBottomSheetViewModel()
        }
        
        func makeBibleVerseDetailBottomSheetVM(bibleBook: BibleBook, keyword: String) -> BibleVerseDetailBottomSheetViewModelProtocol {
            made.append("bibleVerseDetailVM(\(keyword))")
            return MockBibleVerseDetailBottomSheetViewModel()
        }
        
        func makeRecentSearchesBottomSheetVM() -> RecentSearchesBottomSheetViewModelProtocol {
            made.append("recentSearchesVM")
            return MockRecentSearchesBottomSheetViewModel()
        }
        
        func makePopularPlacesBottomSheetVM() -> PopularPlacesBottomSheetViewModelProtocol {
            made.append("popularPlacesVM")
            return MockPopularPlacesBottomSheetViewModel()
        }
        
        func makeMyPageBottomSheetVM() -> MyPageBottomSheetViewModelProtocol {
            made.append("myPageVM")
            return MockMyPageBottomSheetViewModel(menuItems: [])
        }
        
        func makeAccountManagementBottomSheetVM() -> AccountManagementBottomSheetViewModelProtocol {
            made.append("accountManagementVM")
            return MockAccountManagementBottomSheetViewModel()
        }
        
        func makeReportBottomSheetVM(placeId: String, reportType: PlaceReportType) -> ReportBottomSheetViewModelProtocol {
            made.append("reportVM(\(placeId), \(reportType))")
            return MockReportBottomSheetViewModel()
        }
        
        func makeMainVM() -> MainViewModelProtocol {
            made.append("mainVM")
            return MockMainViewModel()
        }
    
    
    func makePlaceModificationBottomSheerVM(placeId: String) -> BibleAtlas.PlaceModificationBottomSheetViewModelProtocol {
        made.append("placeModificationBottomSheetVM")
        return MockPlaceModificationBottomSheetViewModel()
    }
    
    func configure(navigator: BottomSheetNavigator, appCoordinator: AppCoordinatorProtocol) {}
}

// === Stub VMs (최소 구현) ===
// 각 프로토콜이 요구하는 속성/메서드를 "크래시 안 나게"만 채움

final class StubHomeBottomSheetVM: HomeBottomSheetViewModelProtocol {
    let isSearchingMode$ = BehaviorRelay<Bool>(value: false)
    let keyword$ = BehaviorRelay<String>(value: "")
    let cancelButtonTapped$ = PublishRelay<Void>()

    let forceMedium$ = PublishRelay<Void>()
    let restoreDetents$ = PublishRelay<Void>()

    func transform(input: HomeBottomSheetViewModel.Input) -> HomeBottomSheetViewModel.Output {
        return .init(
            profile$: .just(nil),
            isLoggedIn$: .just(false),
            screenMode$: Observable.just(.home),
            keyword$: keyword$,
            keywordText$: keyword$.asDriver(),
            isSearchingMode$: isSearchingMode$.asObservable(),
            forceMedium$: forceMedium$.asObservable(),
            restoreDetents$: restoreDetents$.asObservable()
        )
    }
}




