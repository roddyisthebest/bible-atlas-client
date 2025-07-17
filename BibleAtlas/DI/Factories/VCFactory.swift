//
//  VCFactory.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/28/25.
//

import UIKit
protocol VCFactoryProtocol:AnyObject {
    //TODO: VC 직접 타입 리턴 프로토콜로 변경 필요
    func makeHomeBottomSheetVC(
        homeVM: HomeBottomSheetViewModelProtocol,
        homeContentVM:HomeContentViewModelProtocol,
        searchResultVM:SearchResultViewModelProtocol,
        searchReadyVM:SearchReadyViewModelProtocol) -> HomeBottomSheetViewController
    
    func makeLoginBottomSheetVC(vm:LoginBottomSheetViewModelProtocol) -> LoginBottomSheetViewController
    func makeMyCollectionBottomSheetVC(vm:MyCollectionBottomSheetViewModelProtocol) -> MyCollectionBottomSheetViewController;
    func makePlaceDetailBottomSheetVC(vm:PlaceDetailViewModelProtocol, placeId:String) -> PlaceDetailViewController
    func makeMemoBottomSheetVC(vm:MemoBottomSheetViewModelProtocol) -> MemoBottomSheetViewController
    
    func makePlaceModificationBottomSheetVC(vm:PlaceModificationBottomSheetViewModelProtocol) -> PlaceModificationBottomSheetViewController
    
    func makePlaceTypesBottomSheetVC(vm:PlaceTypesBottomSheetViewModelProtocol) -> PlaceTypesBottomSheetViewController
    
    func makePlaceCharactersBottomSheetVC(vm:PlaceCharactersBottomSheetViewModelProtocol) -> PlaceCharactersBottomSheetViewController
    
    func makePlacesByTypeBottomSheetVC(vm:PlacesByTypeBottomSheetViewModelProtocol, placeTypeId:Int) -> PlacesByTypeBottomSheetViewController
    
    func makePlacesByCharacterBottomSheetVC(vm:PlacesByCharacterBottomSheetViewModelProtocol, character:String) -> PlacesByCharacterBottomSheetViewController
    
    func makeBibleVerseDetailBottomSheetVC(vm:BibleVerseDetailBottomSheetViewModelProtocol, keyword:String) -> BibleVerseDetailBottomSheetViewController
    
    func makeRecentSearchesBottomSheetVC(vm:RecentSearchesBottomSheetViewModelProtocol) -> RecentSearchesBottomSheetViewController
    
    func makePopularPlacesBottomSheetVC(vm:PopularPlacesBottomSheetViewModelProtocol) ->
        PopularPlacesBottomSheetViewController
    
    func makeMyPageBottomSheetVC(vm:MyPageBottomSheetViewModelProtocol) -> MyPageBottomSheetViewController
    
    
    func setupVC(type: BottomSheetType, sheet: UIViewController) -> Void
}


final class VCFactory:VCFactoryProtocol {

    
    

    

    private let highDetent = UISheetPresentationController.Detent.custom { context in
        return UIScreen.main.bounds.height * 1;
    }
    private let lowDetent = UISheetPresentationController.Detent.custom { context in
        return UIScreen.main.bounds.height * 0.2;
    }
    
    private let centerDetent = UISheetPresentationController.Detent.custom { context in
        return UIScreen.main.bounds.height * 0.5;
    }
    

    func makeHomeBottomSheetVC(homeVM: HomeBottomSheetViewModelProtocol, homeContentVM: HomeContentViewModelProtocol, searchResultVM: SearchResultViewModelProtocol, searchReadyVM: SearchReadyViewModelProtocol) -> HomeBottomSheetViewController {
        
        let homeContentVC = HomeContentViewController(homeContentViewModel: homeContentVM);
        let searchResultVC = SearchResultViewController(searchResultViewModel: searchResultVM);
        let searchReadyVC = SearchReadyViewController(searchReadyViewModel: searchReadyVM);
        
        
        let vc = HomeBottomSheetViewController(homeBottomSheetViewModel: homeVM, homeContentViewController: homeContentVC, searchReadyViewController: searchReadyVC, searchResultViewController: searchResultVC)
        setupVC(type: .home, sheet:vc)
        return vc;
    }
    
    
    func makeLoginBottomSheetVC(vm: LoginBottomSheetViewModelProtocol) -> LoginBottomSheetViewController {
        let vc = LoginBottomSheetViewController(loginBottomSheetViewModel: vm);
        return vc;
    }
    
    func makeMyCollectionBottomSheetVC(vm:MyCollectionBottomSheetViewModelProtocol) -> MyCollectionBottomSheetViewController{
        let vc = MyCollectionBottomSheetViewController(myCollectionBottomSheetViewModel: vm);
        return vc;
        
    }

    
    func makePlaceDetailBottomSheetVC(vm: PlaceDetailViewModelProtocol, placeId:String) -> PlaceDetailViewController {
        let vc = PlaceDetailViewController(placeDetailViewModel: vm, placeId: placeId);
        setupVC(type: .placeDetail(placeId), sheet: vc);
        return vc;
    }
    
    func makeMemoBottomSheetVC(vm:MemoBottomSheetViewModelProtocol) -> MemoBottomSheetViewController {
        let vc = MemoBottomSheetViewController(memoBottomSheetViewModel: vm);
        setupVC(type: .memo("123"), sheet: vc);
        return vc;
    }
    
    
    func makePlaceModificationBottomSheetVC(vm: PlaceModificationBottomSheetViewModelProtocol) -> PlaceModificationBottomSheetViewController {
        let vc = PlaceModificationBottomSheetViewController(vm: vm);
        setupVC(type:.placeModification("123"),sheet: vc)
        return vc;
    }
    
    
    func makePlaceTypesBottomSheetVC(vm: PlaceTypesBottomSheetViewModelProtocol) -> PlaceTypesBottomSheetViewController {
        let vc = PlaceTypesBottomSheetViewController(vm: vm);
        setupVC(type: .placeTypes, sheet: vc);
        return vc;
    }
    
    func makePlaceCharactersBottomSheetVC(vm: PlaceCharactersBottomSheetViewModelProtocol) -> PlaceCharactersBottomSheetViewController {
        let vc = PlaceCharactersBottomSheetViewController(vm: vm);
        setupVC(type: .placeCharacters, sheet:vc)
        return vc;
    }
    
    func makePlacesByTypeBottomSheetVC(vm: PlacesByTypeBottomSheetViewModelProtocol, placeTypeId:Int) -> PlacesByTypeBottomSheetViewController {
        let vc = PlacesByTypeBottomSheetViewController(vm: vm);
        setupVC(type: .placesByType(placeTypeId), sheet: vc);
        return vc;
    }
    
    func makePlacesByCharacterBottomSheetVC(vm: PlacesByCharacterBottomSheetViewModelProtocol, character:String) -> PlacesByCharacterBottomSheetViewController {
        let vc = PlacesByCharacterBottomSheetViewController(vm: vm);
        setupVC(type: .placesByCharacter(character), sheet: vc);
        return vc;
    }
    
    func makeBibleVerseDetailBottomSheetVC(vm: BibleVerseDetailBottomSheetViewModelProtocol, keyword:String) -> BibleVerseDetailBottomSheetViewController {
        let vc = BibleVerseDetailBottomSheetViewController(bibleVerseDetailBottomSheetViewModel: vm);
        setupVC(type: .bibleVerseDetail(keyword),sheet: vc);
        return vc;
    }
    
    func makeRecentSearchesBottomSheetVC(vm: RecentSearchesBottomSheetViewModelProtocol) -> RecentSearchesBottomSheetViewController {
        let vc = RecentSearchesBottomSheetViewController(recentSearchesBottomSheetViewModel: vm);
        setupVC(type: .recentSearches,sheet: vc);
        return vc;
    }
    
    func makePopularPlacesBottomSheetVC(vm: PopularPlacesBottomSheetViewModelProtocol) -> PopularPlacesBottomSheetViewController {
        let vc = PopularPlacesBottomSheetViewController(popularPlacesBottomSheetViewModel: vm);
        setupVC(type: .popularPlaces, sheet: vc)
        return vc;
    }
    
    func makeMyPageBottomSheetVC(vm: MyPageBottomSheetViewModelProtocol) -> MyPageBottomSheetViewController {
        let vc = MyPageBottomSheetViewController(myPageBottomSheetViewModel: vm)
        setupVC(type: .myPage, sheet: vc)
        return vc;
    }

    func setupVC(type: BottomSheetType, sheet: UIViewController) {
        switch(type){
        case .home:
            if let sheet = sheet.sheetPresentationController {
                sheet.detents = [.large(), .medium(), lowDetent]
                sheet.largestUndimmedDetentIdentifier = .medium;
                sheet.selectedDetentIdentifier = .medium
                sheet.prefersGrabberVisible = true // 위쪽 핸들 표시
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false // 스크롤 시 확장 가능
            }
            
            sheet.isModalInPresentation = true
            
        case .login:
            if let sheet = sheet.sheetPresentationController {
                
                sheet.detents = [highDetent, centerDetent] // 높이 조절 가능 (중간, 전체 화면)
                sheet.prefersGrabberVisible = false // 위쪽 핸들 표시
                sheet.prefersScrollingExpandsWhenScrolledToEdge = true // 스크롤 시 확장 가능
            }
            sheet.isModalInPresentation = false
        case .placeDetail:
            if let sheet = sheet.sheetPresentationController {
                
                sheet.detents = [.large(), .medium(), lowDetent] // 높이 조절 가능 (중간, 전체 화면)
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false // 스크롤 시 확장 가능
                
                sheet.largestUndimmedDetentIdentifier = .medium;
                sheet.selectedDetentIdentifier = .medium
                sheet.prefersGrabberVisible = true // 위쪽 핸들 표시

            }
            sheet.isModalInPresentation = true
        
            
        case .memo:
            if let sheet = sheet.sheetPresentationController {
                sheet.detents = [.large()] // 높이 조절 가능 (중간, 전체 화면)
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false // 스크롤 시 확장 가능
                sheet.prefersGrabberVisible = false // 위쪽 핸들 표시
            }
        case .placeModification:
            if let sheet = sheet.sheetPresentationController {
                sheet.detents = [.large()] // 높이 조절 가능 (중간, 전체 화면)
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false // 스크롤 시 확장 가능
                sheet.prefersGrabberVisible = false // 위쪽 핸들 표시
            }
        case .myPage:
            if let sheet = sheet.sheetPresentationController {
                sheet.detents = [.large(),.medium()]
                sheet.prefersScrollingExpandsWhenScrolledToEdge = true
                sheet.prefersGrabberVisible = true
            }

        default:
            if let sheet = sheet.sheetPresentationController {
                sheet.detents = [.large()] // 높이 조절 가능 (중간, 전체 화면)
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false // 스크롤 시 확장 가능
                sheet.prefersGrabberVisible = false // 위쪽 핸들 표시
            }
            sheet.isModalInPresentation = true
        
        
            
        }
    }
    
}
