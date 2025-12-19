//
//  BottomSheetCoordinator.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/19/25.
//

import UIKit


enum BottomSheetType:Equatable {
    case home
    case login
    case myCollection(PlaceFilter)
    case placeDetail(String)
    case placeDetailPrevious
    case memo(String)
    case placeModification(String)
    case placeTypes
    case placeCharacters
    case bibles
    case placesByType(PlaceTypeName)
    case placesByCharacter(String)
    case placesByBible(BibleBook)
    case placeReport(String, PlaceReportType)
    case bibleVerseDetail(BibleBook, String, String?)
    case bibleBookVerseList(String, BibleBook?)
    case recentSearches
    case popularPlaces
    case myPage
    case accountManagement
    case report
}


protocol Presentable:AnyObject{
    func present(vc:UIViewController, animated:Bool)
    func dismiss(animated:Bool)
    func topMostViewController() -> UIViewController
}

protocol BottomSheetNavigator: AnyObject {
    func present(_ type: BottomSheetType)
    func dismiss(animated:Bool)
    func dismissFromDetail(animated:Bool)
    func setPresenter(_ presenter: Presentable?)
    
}

final class BottomSheetCoordinator: BottomSheetNavigator {

    private weak var presenter: Presentable?
    private let vcFactory: VCFactoryProtocol;
    private let vmFactory: VMFactoryProtocol;
    
    private let notificationService: RxNotificationServiceProtocol?;
        
    private var placeHistory: [String] = []
    private var currentPlaceId: String? = nil {
        didSet{
            guard let placeId = currentPlaceId else {
                self.notificationService?.post(.resetGeoJson, object: nil)
                return;
            }
            self.notificationService?.post(.fetchGeoJsonRequired, object: placeId)
        }
    }
    
    
    
    
    init(vcFactory: VCFactoryProtocol, vmFactory:VMFactoryProtocol, notificationService:RxNotificationServiceProtocol) {
        self.vmFactory = vmFactory;
        self.vcFactory = vcFactory;
        self.notificationService = notificationService
    }

    func setPresenter(_ presenter: Presentable?) {
        self.presenter = presenter
    }
    
    func presentFromTopVC(_ vc: UIViewController){
        DispatchQueue.main.async {
            guard let baseVC = self.presenter else { return }
            let topVC = baseVC.topMostViewController()
                

            
            topVC.present(vc, animated: true)
        }
    }
    
    
    private func presentedVCStack(from root: UIViewController) -> [UIViewController] {
        var stack: [UIViewController] = []
        var current = root.presentedViewController

        while let vc = current {
            stack.append(vc)
            current = vc.presentedViewController
        }

        return stack
    }
    

    private let lowDetent = UISheetPresentationController.Detent.custom { context in
        return UIScreen.main.bounds.height * 0.2;
    }
    
    private func presentDetail(placeId:String){
    
        DispatchQueue.main.async {
            guard let baseVC = self.presenter as? UIViewController else { return }

            let topVC = baseVC.topMostViewController()

            guard let currentPlaceId = self.currentPlaceId else {
                self.notificationService?.post(.sheetCommand, object: SheetCommand.forceMedium)
                let vm = self.vmFactory.makePlaceDetailBottomSheetVM(placeId: placeId);
                let vc = self.vcFactory.makePlaceDetailBottomSheetVC(vm: vm, placeId: placeId);
                
                topVC.present(vc, animated: true)
                self.currentPlaceId = placeId;
                return;
            }
            self.placeHistory.append(currentPlaceId)
            let prevPlaceId = currentPlaceId
            self.currentPlaceId = placeId;


            
            let object:[String:String?] = ["placeId":placeId, "prevPlaceId":prevPlaceId]
            self.notificationService?.post(.fetchPlaceRequired, object: object)

            
        }

    }
    
    func dismissFromDetail(animated: Bool){
        DispatchQueue.main.async {
    
            self.notificationService?.post(.sheetCommand, object: SheetCommand.restoreDetents)
            
            self.dismiss(animated: animated)
            self.placeHistory = []
            self.currentPlaceId = nil
            
        }
        
        
    }
    
    private func backDetail(){
     
        guard let newPlaceId = self.placeHistory.popLast() else {
            return;
        }
        
        self.currentPlaceId = newPlaceId;

        guard let prevPlaceId = self.placeHistory.last else {
            let object:[String:String?] = ["placeId":newPlaceId, "prevPlaceId":nil]
            self.notificationService?.post(.fetchPlaceRequired, object: object)
            return;
        }
        
        let object:[String:String?] = ["placeId":newPlaceId, "prevPlaceId":prevPlaceId]
        self.notificationService?.post(.fetchPlaceRequired, object: object)

        

    }

    func present(_ type: BottomSheetType) {
        switch(type){
        case .home:
            let homeVM = vmFactory.makeHomeBottomSheetVM();
            
            let homeContentVM = vmFactory.makeHomeContentVM();
            let searchResultVM = vmFactory.makeSearchResultVM(keyword$: homeVM.keyword$.asObservable(), isSearchingMode$: homeVM.isSearchingMode$.asObservable(), cancelButtonTapped$: homeVM.cancelButtonTapped$.asObservable());
            let searchReadyVM = vmFactory.makeSearchReadyVM();
            
            
            let vc = vcFactory.makeHomeBottomSheetVC(homeVM: homeVM, homeContentVM: homeContentVM, searchResultVM: searchResultVM, searchReadyVM: searchReadyVM);
            
            presentFromTopVC(vc);
            
        case .login:
            let vm = vmFactory.makeLoginBottomSheetVM();
            let vc = vcFactory.makeLoginBottomSheetVC(vm: vm);
            presentFromTopVC(vc);
            
        case .myCollection(let filter):
            let vm = vmFactory.makeMyCollectionBottomSheetVM(filter: filter);
            let vc = vcFactory.makeMyCollectionBottomSheetVC(vm: vm);
            presentFromTopVC(vc)
            
        case .placeDetail(let placeId):
            presentDetail(placeId: placeId)
            
        case .placeDetailPrevious:
            backDetail()
            
        case .memo(let placeId):
            let vm = vmFactory.makeMemoBottomSheetVM(placeId: placeId);
            let vc = vcFactory.makeMemoBottomSheetVC(vm: vm);
            presentFromTopVC(vc)
            
            
        case .placeModification(let placeId):
            let vm = vmFactory.makePlaceModificationBottomSheerVM(placeId: placeId);
            let vc = vcFactory.makePlaceModificationBottomSheetVC(vm: vm);
            
            presentFromTopVC(vc)
            
        case .placeTypes:
            let vm = vmFactory.makePlaceTypesBottomSheetVM();
            let vc = vcFactory.makePlaceTypesBottomSheetVC(vm: vm);
            presentFromTopVC(vc);
            
            
        case .placeCharacters:
            let vm = vmFactory.makePlaceCharactersBottomSheetVM();
            let vc = vcFactory.makePlaceCharactersBottomSheetVC(vm: vm);
            presentFromTopVC(vc)
            
        case .bibles:
            let vm = vmFactory.makeBiblesBottomSheetVM();
            let vc = vcFactory.makeBiblesBottomSheetVC(vm: vm);
            presentFromTopVC(vc)
            
        case .placesByType(let placeTypeName):
            let vm = vmFactory.makePlacesByTypeBottomSheetVM(placeTypeName: placeTypeName);
            let vc = vcFactory.makePlacesByTypeBottomSheetVC(vm: vm, placeTypeName: placeTypeName);
            
            presentFromTopVC(vc)
            
        case .placesByCharacter(let character):
            let vm = vmFactory.makePlacesByCharacterBottomSheetVM(character: character);
            let vc = vcFactory.makePlacesByCharacterBottomSheetVC(vm: vm, character: character);
            presentFromTopVC(vc)
            
        case .placesByBible(let bibleBook):
            let vm = vmFactory.makePlacesByBibleBottomSheetVM(bible: bibleBook)
            let vc = vcFactory.makePlacesByBibleBottomSheetVC(vm: vm, bibleBook: bibleBook)
            presentFromTopVC(vc)
            
        case .bibleVerseDetail(let bibleBook, let keyword, let placeName):
            let vm = vmFactory.makeBibleVerseDetailBottomSheetVM(bibleBook:bibleBook, keyword: keyword, placeName: placeName);
            let vc = vcFactory.makeBibleVerseDetailBottomSheetVC(vm: vm, keyword: keyword);
            presentFromTopVC(vc)
            
        case .recentSearches:
            let vm = vmFactory.makeRecentSearchesBottomSheetVM();
            let vc = vcFactory.makeRecentSearchesBottomSheetVC(vm: vm);
            presentFromTopVC(vc)
            
        case .popularPlaces:
            let vm = vmFactory.makePopularPlacesBottomSheetVM();
            let vc = vcFactory.makePopularPlacesBottomSheetVC(vm: vm);
            presentFromTopVC(vc)
        
        case .myPage:
            let vm = vmFactory.makeMyPageBottomSheetVM();
            let vc = vcFactory.makeMyPageBottomSheetVC(vm: vm);
            presentFromTopVC(vc)
            
        case .accountManagement:
            let vm = vmFactory.makeAccountManagementBottomSheetVM();
            let vc = vcFactory.makeAccountManagementBottomSheetVC(vm: vm);
            presentFromTopVC(vc)
        case .placeReport(let placeId, let reportType):
            let vm = vmFactory.makePlaceReportBottomSheetVM(placeId: placeId, reportType: reportType)
            let vc = vcFactory.makePlaceReportBottomSheetVC(vm: vm)
            presentFromTopVC(vc)
            
        case .bibleBookVerseList(let placeId, let bibleBook):
            let vm = vmFactory.makeBibleBookVerseListBottomSheetVM(placeId: placeId, bibleBook: bibleBook)
            let vc = vcFactory.makeBibleBookVerseListBottomSheetVC(vm: vm);
            
            presentFromTopVC(vc)
        case .report:
            let vm = vmFactory.makeReportBottomSheetVM();
            let vc = vcFactory.makeReportBottomSheetVC(vm: vm);
            presentFromTopVC(vc);
        }
    
    }

    func dismiss(animated:Bool) {
        DispatchQueue.main.async {
            guard let baseVC = self.presenter else { return }
            let topVC = baseVC.topMostViewController()
            topVC.dismiss(animated: animated)
         }
    }
    
    
    
    
    
    
    

    
}
