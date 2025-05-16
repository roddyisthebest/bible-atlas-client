//
//  MemoBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/10/25.
//


import Foundation
import RxSwift
import RxRelay

protocol MemoBottomSheetViewModelProtocol {
    func transform(input:MemoBottomSheetViewModel.Input)
}


final class MemoBottomSheetViewModel:MemoBottomSheetViewModelProtocol{

    
    private let disposeBag = DisposeBag();
    private weak var navigator: BottomSheetNavigator?
    
    private let placeId:String?
    
    
    init(navigator:BottomSheetNavigator?, placeId:String){
        self.navigator = navigator
        self.placeId = placeId;
    }
    
    
    func transform(input: Input)  {
        
        input.confirmButtonTapped$.subscribe(onNext: { [weak self] text in print("\(text)")}).disposed(by: disposeBag)
               
        input.deleteButtonTapped$.subscribe(onNext:{
            [weak self] in
        }).disposed(by: disposeBag)
        
        input.cancelButtonTapped$.subscribe(onNext: {
            [weak self] in
            self?.navigator?.dismiss(animated: true)
        }).disposed(by: disposeBag)
    }
    
    public struct Input {
        let cancelButtonTapped$:Observable<Void>
        let confirmButtonTapped$:Observable<String>
        let deleteButtonTapped$:Observable<Void>
    }
    

}
