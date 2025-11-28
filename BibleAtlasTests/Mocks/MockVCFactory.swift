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
    func present(vc: BibleAtlas.ViewController, animated: Bool) {
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
    func makePlaceReportBottomSheetVC(vm: BibleAtlas.PlaceReportBottomSheetViewModelProtocol) -> UIViewController {
        FakeSheetVC("placeReport")
    }
    
    func makeBibleBookVerseListBottomSheetVC(vm: BibleAtlas.BibleBookVerseListBottomSheetViewModelProtocol) -> UIViewController {
        FakeSheetVC("verseList")
    }
    

    // 호출 기록
    struct Call { let name: String }
    private(set) var calls: [Call] = []

    // MARK: - Implemented for tests

    func makeHomeBottomSheetVC(
        homeVM: HomeBottomSheetViewModelProtocol,
        homeContentVM: HomeContentViewModelProtocol,
        searchResultVM: SearchResultViewModelProtocol,
        searchReadyVM: SearchReadyViewModelProtocol
    ) -> UIViewController {
        calls.append(.init(name: "makeHomeBottomSheetVC"))
        return FakeSheetVC("homeBottomSheet")
    }

    func makePlaceDetailBottomSheetVC(vm: PlaceDetailViewModelProtocol, placeId: String) -> UIViewController {
        calls.append(.init(name: "makePlaceDetailBottomSheetVC:\(placeId)"))
        // ✅ IdentifiableBottomSheet 채택한 VC를 리턴해야 코디네이터에서 캐스팅/검증 OK
        return FakePlaceDetailVC(placeId)
    }

    func makeMainVC(vm: MainViewModelProtocol) -> UIViewController & BibleAtlas.Presentable {
        calls.append(.init(name: "makeMainVC"))
        return FakeMainVC()
    }

    func setupVC(type: BottomSheetType, sheet: UIViewController) {
        // 필요시 공통 시트 옵션(코너, 라지/미디엄 등) 지정
        sheet.modalPresentationStyle = .pageSheet
        // sheet.sheetPresentationController?.prefersGrabberVisible = true  // 등등
    }

    // MARK: - Not used in current tests (fill later or trap)
    func makeLoginBottomSheetVC(vm: LoginBottomSheetViewModelProtocol) -> UIViewController { FakeSheetVC("login") }
    func makeMyCollectionBottomSheetVC(vm: MyCollectionBottomSheetViewModelProtocol) -> UIViewController { FakeSheetVC("myCollection") }
    func makeMemoBottomSheetVC(vm: MemoBottomSheetViewModelProtocol) -> UIViewController { FakeSheetVC("memo") }
    func makePlaceModificationBottomSheetVC(vm: PlaceModificationBottomSheetViewModelProtocol) -> UIViewController { FakeSheetVC("placeModification") }
    func makePlaceTypesBottomSheetVC(vm: PlaceTypesBottomSheetViewModelProtocol) -> UIViewController { FakeSheetVC("placeTypes") }
    func makePlaceCharactersBottomSheetVC(vm: PlaceCharactersBottomSheetViewModelProtocol) -> UIViewController { FakeSheetVC("placeCharacters") }
    func makeBiblesBottomSheetVC(vm: BiblesBottomSheetViewModelProtocol) -> UIViewController { FakeSheetVC("bibles") }
    func makePlacesByTypeBottomSheetVC(vm: PlacesByTypeBottomSheetViewModelProtocol, placeTypeName: PlaceTypeName) -> UIViewController { FakeSheetVC("placesByType") }
    func makePlacesByCharacterBottomSheetVC(vm: PlacesByCharacterBottomSheetViewModelProtocol, character: String) -> UIViewController { FakeSheetVC("placesByCharacter") }
    func makePlacesByBibleBottomSheetVC(vm: PlacesByBibleBottomSheetViewModelProtocol, bibleBook: BibleBook) -> UIViewController { FakeSheetVC("placesByBible") }
    func makeBibleVerseDetailBottomSheetVC(vm: BibleVerseDetailBottomSheetViewModelProtocol, keyword: String) -> UIViewController { FakeSheetVC("bibleVerseDetail") }
    func makeRecentSearchesBottomSheetVC(vm: RecentSearchesBottomSheetViewModelProtocol) -> UIViewController { FakeSheetVC("recentSearches") }
    func makePopularPlacesBottomSheetVC(vm: PopularPlacesBottomSheetViewModelProtocol) -> UIViewController { FakeSheetVC("popularPlaces") }
    func makeMyPageBottomSheetVC(vm: MyPageBottomSheetViewModelProtocol) -> UIViewController { FakeSheetVC("myPage") }
    func makeAccountManagementBottomSheetVC(vm: AccountManagementBottomSheetViewModelProtocol) -> UIViewController { FakeSheetVC("accountManagement") }
    func makeReportBottomSheetVC(vm: ReportBottomSheetViewModelProtocol) -> UIViewController { FakeSheetVC("report") }
}
