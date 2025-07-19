//
//  BottomSheetCoordinator.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/19/25.
//

import UIKit
import PanModal


enum BottomSheetType {
    case home
    case login
    case myCollection(PlaceFilter)
    case placeDetail(String)
    case memo(String)
    case placeModification(String)
    case placeTypes
    case placeCharacters
    case placesByType(Int)
    case placesByCharacter(String)
    case bibleVerseDetail(String)
    case recentSearches
    case popularPlaces
    case myPage
    case accountManagement
}


protocol Presentable:AnyObject{
    func present(vc:ViewController, animated:Bool)
    func dismiss(animated:Bool)
    func topMostViewController() -> UIViewController
}

protocol BottomSheetNavigator: AnyObject {
    func present(_ type: BottomSheetType)
    func dismiss(animated:Bool)
    func dismissFromDetail(animated:Bool)
    func replace(with type: BottomSheetType)
    
}

final class BottomSheetCoordinator: BottomSheetNavigator {

    private weak var presenter: Presentable?
    private let vcFactory: VCFactoryProtocol;
    private let vmFactory: VMFactoryProtocol;
    
    private let notificationService: RxNotificationServiceProtocol?;
        
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
    
    
    private var prevDetents:[[UISheetPresentationController.Detent]] = []
    
    private let lowDetent = UISheetPresentationController.Detent.custom { context in
        return UIScreen.main.bounds.height * 0.2;
    }
    
    private func presentDetail(_ vc:UIViewController, placeId:String){
        
        
        DispatchQueue.main.async {
            guard let baseVC = self.presenter as? UIViewController else { return }
            let stack = self.presentedVCStack(from: baseVC)
            let topVC = baseVC.topMostViewController()

            guard let currentPlaceId = self.currentPlaceId else {
                stack.forEach { vc in
            
                    weak var weakVC = vc

                    weakVC?.sheetPresentationController?.animateChanges {
                        guard let detents = weakVC?.sheetPresentationController?.detents else{
                            return
                        }
                        self.prevDetents.append(detents)

                        weakVC?.sheetPresentationController?.detents = [.medium()]
                        weakVC?.sheetPresentationController?.largestUndimmedDetentIdentifier = .medium;
                        weakVC?.sheetPresentationController?.selectedDetentIdentifier = .medium
                    }
                 
                }
                topVC.present(vc, animated: true)
                self.currentPlaceId = placeId;
                return;
            }
            
            self.currentPlaceId = placeId;
            self.notificationService?.post(.fetchPlaceRequired, object: placeId)

            
        }

    }
    
    func dismissFromDetail(animated: Bool){
        guard let baseVC = self.presenter as? UIViewController else { return }
        
        DispatchQueue.main.async {
            
            
            let stack = self.presentedVCStack(from: baseVC)
            
            for i in 0..<stack.count-1{
                let vc = stack[i];
                vc.sheetPresentationController?.animateChanges {
                    vc.sheetPresentationController?.detents = self.prevDetents[i]
                }
            }
            
            self.dismiss(animated: animated)
            self.currentPlaceId = nil

        }
        
        
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
            
            let vm = vmFactory.makePlaceDetailBottomSheetVM(placeId: placeId);
            let vc = vcFactory.makePlaceDetailBottomSheetVC(vm: vm, placeId: placeId);
            presentDetail(vc, placeId: placeId)
            
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
            
        case .placesByType(let placeTypeId):
            let vm = vmFactory.makePlacesByTypeBottomSheetVM(placeTypeId: placeTypeId);
            let vc = vcFactory.makePlacesByTypeBottomSheetVC(vm: vm, placeTypeId: placeTypeId);
            
            presentFromTopVC(vc)
            
        case .placesByCharacter(let character):
            let vm = vmFactory.makePlacesByCharacterBottomSheetVM(character: character);
            let vc = vcFactory.makePlacesByCharacterBottomSheetVC(vm: vm, character: character);
            presentFromTopVC(vc)
            
        case .bibleVerseDetail(let keyword):
            let vm = vmFactory.makeBibleVerseDetailBottomSheetVM(keyword: keyword);
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
        }
    
    }

    func dismiss(animated:Bool) {
        DispatchQueue.main.async {
            guard let baseVC = self.presenter else { return }
            let topVC = baseVC.topMostViewController()
            topVC.dismiss(animated: animated)
         }
    }
    
    
    
    
    
    
    
    func replace(with type: BottomSheetType) {
        self.dismiss(animated: false)
        self.present(type)
    }
    
}
