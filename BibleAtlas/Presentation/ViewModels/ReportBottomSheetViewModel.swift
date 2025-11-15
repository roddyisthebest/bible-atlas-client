//
//  ReportBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 11/15/25.
//

import Foundation
import RxSwift
import RxRelay

protocol ReportBottomSheetViewModelProtocol {
    func transform(input:ReportBottomSheetViewModel.Input) -> ReportBottomSheetViewModel.Output
}


final class ReportBottomSheetViewModel:ReportBottomSheetViewModelProtocol{

    
    private let disposeBag = DisposeBag();
    private weak var navigator: BottomSheetNavigator?
    
    private let reportUsecase: ReportUsecaseProtocol?
    
    
    private let interactionError$ = BehaviorRelay<NetworkError?>(value: nil)
    
    private let isLoading$ = BehaviorRelay<Bool>(value: false);
    private let isSuccess$ = BehaviorRelay<Bool?>(value: nil);

    init(navigator:BottomSheetNavigator?, reportUsecase: ReportUsecaseProtocol?){
        self.navigator = navigator
        self.reportUsecase = reportUsecase
    }
    
    
    func transform(input: Input) -> Output {
    
        input.confirmButtonTapped$.subscribe(onNext: { [weak self] props in
            let (comment, type) = props;
            
            guard let comment = comment, !comment.trimmingCharacters(in: .whitespaces).isEmpty else{
                self?.interactionError$.accept(.clientError(L10n.Report.commentRequired))
                return;
            }
            
            guard let type = type else{
                self?.interactionError$.accept(.clientError(L10n.Report.typeRequired))
                return;
            }
            
            
            self?.createReport(comment: comment, type: type)
        }).disposed(by: disposeBag)
               
       
        input.cancelButtonTapped$.subscribe(onNext: {
            [weak self] in
            self?.navigator?.dismiss(animated: true)
        }).disposed(by: disposeBag)
        
        return Output(
            interactionError$: interactionError$.asObservable(),
            isLoading$: isLoading$.asObservable(),
            isSuccess$: isSuccess$.asObservable()
        )

    }
    
    
    private func createReport(comment:String, type:ReportType){
        if(comment.trimmingCharacters(in: .whitespaces).isEmpty){
            return
        }
        
        self.isLoading$.accept(true)
        Task{
            defer{
                self.isLoading$.accept(false)
            }
            
            guard let usecase = self.reportUsecase else {
                self.interactionError$.accept(.clientError(L10n.Report.diError))
                return
            }
            
            let result = await usecase.createReport(comment: comment, type: type);
            
            switch(result){
            case .success:
                isSuccess$.accept(true)
            case .failure(let error):
                interactionError$.accept(error)
            }
        }
    }
    
    public struct Input {
        let viewLoaded$:Observable<Void>
        let cancelButtonTapped$:Observable<Void>
        let confirmButtonTapped$:Observable<(String?, ReportType?)>
    }
    
    public struct Output {
        let interactionError$:Observable<NetworkError?>
        let isLoading$:Observable<Bool>
        let isSuccess$:Observable<Bool?>

    }
    

}

