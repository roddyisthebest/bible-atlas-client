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
    
    init(vcFactory: VCFactoryProtocol, vmFactory:VMFactoryProtocol) {
        self.vmFactory = vmFactory;
        self.vcFactory = vcFactory;
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
    
    private func presentDetail(_ vc:UIViewController){
        
        
        DispatchQueue.main.async {
            guard let baseVC = self.presenter as? UIViewController else { return }
            let stack = self.presentedVCStack(from: baseVC)
            
            let isNotFirst = stack.contains { $0 is PlaceDetailViewController }
            
            if(!isNotFirst){
                self.prevDetents = []
            }

            stack.forEach { vc in
                
                if(!isNotFirst){
                    if let detent = vc.sheetPresentationController?.detents {
                        self.prevDetents.append(detent)
                    }
                }
          
                        
                vc.sheetPresentationController?.animateChanges {
                    vc.sheetPresentationController?.detents = [.medium()]
                    vc.sheetPresentationController?.largestUndimmedDetentIdentifier = .medium;
                    vc.sheetPresentationController?.selectedDetentIdentifier = .medium
                }
             
            }
            
            let detailDetent: [UISheetPresentationController.Detent] = [.large(), .medium()]
            self.prevDetents.append(detailDetent)

            let topVC = baseVC.topMostViewController()
            topVC.present(vc, animated: true)
        
        }

    }
    
    func dismissFromDetail(animated: Bool){
        guard let baseVC = self.presenter as? UIViewController else { return }
        
        DispatchQueue.main.async {
            let stack = self.presentedVCStack(from: baseVC)
            let isLast =  stack.filter { $0 is PlaceDetailViewController }.count == 1;
            print(isLast,"isLast")
            if(!isLast){
            
                self.dismiss(animated: animated)
                
                let stackIdx = stack.count - 2
                
                if(stackIdx < 0) {
                    return;
                }
                
                let behindVC = stack[stackIdx]
                behindVC.sheetPresentationController?.detents = [.large(),.medium()]
                return;
            }
            
            for i in 0..<stack.count-1{
                let vc = stack[i];
                vc.sheetPresentationController?.animateChanges {
                    vc.sheetPresentationController?.detents = self.prevDetents[i]
                }
            }
            
            self.dismiss(animated: animated)

        }
        
        
    }

    func present(_ type: BottomSheetType) {
        switch(type){
        case .home:
            let vm = vmFactory.makeHomeBottomSheetVM();
            let vc = vcFactory.makeHomeBottomSheetVC(vm: vm);
            
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
            let vc = vcFactory.makePlaceDetailBottomSheetVC(vm: vm);
            presentDetail(vc)
            
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
