//
//  MockVCFactory.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/25/25.
//

import UIKit
@testable import BibleAtlas

/// 공통으로 쓰는 가벼운 pageSheet VC
final class FakeSheetVC: UIViewController {
    let tag: String
    init(_ tag: String) {
        self.tag = tag
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        view.backgroundColor = .white
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// placeDetail 용: 아이덴티티가 필요해서 IdentifiableBottomSheet 채택
final class FakePlaceDetailVC: UIViewController, IdentifiableBottomSheet {
    let placeId: String
    init(_ placeId: String) {
        self.placeId = placeId
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        view.backgroundColor = .white
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    var bottomSheetIdentity: BottomSheetType { .placeDetail(placeId) }
}

/// main 용: UIViewController & Presentable 조합
final class FakeMainVC: UIViewController, Presentable {
    func present(vc: UIViewController, animated: Bool) {
        super.present(vc, animated: animated)
    }
    
    func dismiss(animated: Bool) {
        super.dismiss(animated: animated)
    }
    
//    func present(vc: ViewController, animated: Bool) { present(vc, animated: animated) }
//    func dismiss(animated: Bool) { dismiss(animated: animated) }
//    func topMostViewController() -> UIViewController { presentedViewController ?? self }
}

final class MockVCFactory: VCFactoryProtocol {
    // 호출 기록
        struct Call { let name: String }
        private(set) var calls: [Call] = []
        
        private func record(_ name: String) {
            calls.append(.init(name: name))
        }

        // MARK: - Report / BibleBookVerseList

        func makePlaceReportBottomSheetVC(vm: BibleAtlas.PlaceReportBottomSheetViewModelProtocol) -> UIViewController {
            record("makePlaceReportBottomSheetVC")
            return FakeSheetVC("placeReport")
        }
        
        func makeBibleBookVerseListBottomSheetVC(vm: BibleAtlas.BibleBookVerseListBottomSheetViewModelProtocol) -> UIViewController {
            record("makeBibleBookVerseListBottomSheetViewController")
            return FakeSheetVC("verseList")
        }

        // MARK: - Home

        func makeHomeBottomSheetVC(
            homeVM: HomeBottomSheetViewModelProtocol,
            homeContentVM: HomeContentViewModelProtocol,
            searchResultVM: SearchResultViewModelProtocol,
            searchReadyVM: SearchReadyViewModelProtocol
        ) -> UIViewController {
            record("makeHomeBottomSheetVC")
            return FakeSheetVC("homeBottomSheet")
        }

        func makePlaceDetailBottomSheetVC(vm: PlaceDetailViewModelProtocol, placeId: String) -> UIViewController {
            record("makePlaceDetailBottomSheetVC:\(placeId)")
            return FakePlaceDetailVC(placeId)
        }

        func makeMainVC(vm: MainViewModelProtocol) -> UIViewController & BibleAtlas.Presentable {
            record("makeMainVC")
            return FakeMainVC()
        }

        func setupVC(type: BottomSheetType, sheet: UIViewController) {
            // 공통 시트 옵션
            sheet.modalPresentationStyle = .pageSheet
        }

        // MARK: - 나머지 BottomSheet VCs (전부 기록 추가)

        func makeLoginBottomSheetVC(vm: LoginBottomSheetViewModelProtocol) -> UIViewController {
            record("makeLoginBottomSheetVC")
            return FakeSheetVC("login")
        }

        func makeMyCollectionBottomSheetVC(vm: MyCollectionBottomSheetViewModelProtocol) -> UIViewController {
            record("makeMyCollectionBottomSheetViewController")
            return FakeSheetVC("myCollection")
        }

        func makeMemoBottomSheetVC(vm: MemoBottomSheetViewModelProtocol) -> UIViewController {
            record("makeMemoBottomSheetViewController")
            return FakeSheetVC("memo")
        }

        func makePlaceModificationBottomSheetVC(vm: PlaceModificationBottomSheetViewModelProtocol) -> UIViewController {
            record("makePlaceModificationBottomSheetViewController")
            return FakeSheetVC("placeModification")
        }

        func makePlaceTypesBottomSheetVC(vm: PlaceTypesBottomSheetViewModelProtocol) -> UIViewController {
            record("makePlaceTypesBottomSheetViewController")
            return FakeSheetVC("placeTypes")
        }

        func makePlaceCharactersBottomSheetVC(vm: PlaceCharactersBottomSheetViewModelProtocol) -> UIViewController {
            record("makePlaceCharactersBottomSheetViewController")
            return FakeSheetVC("placeCharacters")
        }

        func makeBiblesBottomSheetVC(vm: BiblesBottomSheetViewModelProtocol) -> UIViewController {
            record("makeBiblesBottomSheetViewController")
            return FakeSheetVC("bibles")
        }

        func makePlacesByTypeBottomSheetVC(vm: PlacesByTypeBottomSheetViewModelProtocol, placeTypeName: PlaceTypeName) -> UIViewController {
            record("makePlacesByTypeBottomSheetViewController")
            return FakeSheetVC("placesByType")
        }

        func makePlacesByCharacterBottomSheetVC(vm: PlacesByCharacterBottomSheetViewModelProtocol, character: String) -> UIViewController {
            record("makePlacesByCharacterBottomSheetViewController")
            return FakeSheetVC("placesByCharacter")
        }

        func makePlacesByBibleBottomSheetVC(vm: PlacesByBibleBottomSheetViewModelProtocol, bibleBook: BibleBook) -> UIViewController {
            record("makePlacesByBibleBottomSheetViewController")
            return FakeSheetVC("placesByBible")
        }

        func makeBibleVerseDetailBottomSheetVC(vm: BibleVerseDetailBottomSheetViewModelProtocol, keyword: String) -> UIViewController {
            record("makeBibleVerseDetailBottomSheetViewController")
            return FakeSheetVC("bibleVerseDetail")
        }

        func makeRecentSearchesBottomSheetVC(vm: RecentSearchesBottomSheetViewModelProtocol) -> UIViewController {
            record("makeRecentSearchesBottomSheetViewController")
            return FakeSheetVC("recentSearches")
        }

        func makePopularPlacesBottomSheetVC(vm: PopularPlacesBottomSheetViewModelProtocol) -> UIViewController {
            record("makePopularPlacesBottomSheetViewController")
            return FakeSheetVC("popularPlaces")
        }

        func makeMyPageBottomSheetVC(vm: MyPageBottomSheetViewModelProtocol) -> UIViewController {
            record("makeMyPageBottomSheetViewController")
            return FakeSheetVC("myPage")
        }

        func makeAccountManagementBottomSheetVC(vm: AccountManagementBottomSheetViewModelProtocol) -> UIViewController {
            record("makeAccountManagementBottomSheetViewController")
            return FakeSheetVC("accountManagement")
        }

        func makeReportBottomSheetVC(vm: ReportBottomSheetViewModelProtocol) -> UIViewController {
            record("makeReportBottomSheetViewController")
            return FakeSheetVC("report")
        }
}
