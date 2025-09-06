//
//  ReportBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 7/23/25.
//

import Foundation
import RxSwift
import RxRelay

protocol ReportBottomSheetViewModelProtocol{
    func transform(input:ReportBottomSheetViewModel.Input) -> ReportBottomSheetViewModel.Output
}

enum ReportClientError:Error{
    case placeId
    case placeType
}

final class ReportBottomSheetViewModel:ReportBottomSheetViewModelProtocol{
        
    private let disposeBag = DisposeBag();
    
    private weak var navigator: BottomSheetNavigator?
    
    private var placeId:String? = nil
    
    private let reportType$ = BehaviorRelay<PlaceReportType?>(value:nil)
    
    private let isLoading$ = BehaviorRelay<Bool>(value: false)
    private let isSuccess$ = BehaviorRelay<Bool?>(value: nil)
    private let networkError$ = BehaviorRelay<NetworkError?>(value: nil)
    private let clientError$ = BehaviorRelay<ReportClientError?>(value: nil)

    private let placeUsecase:PlaceUsecaseProtocol?

    init(navigator: BottomSheetNavigator?, reportType:PlaceReportType?, placeUsecase:PlaceUsecaseProtocol?, placeId:String?) {
        self.navigator = navigator
        self.reportType$.accept(reportType)
        self.placeUsecase = placeUsecase
        self.placeId = placeId
    }
    
    func transform(input:Input) -> Output{
        
        input.cancelButttonTapped$.subscribe(onNext:{[weak self] in
            self?.navigator?.dismiss(animated: true)
        }).disposed(by: disposeBag)
 
        input.placeTypeCellTapped$.subscribe(onNext:{
            [weak self] placeType in
            self?.reportType$.accept(placeType)
        }).disposed(by: disposeBag)
            
        input.confirmButtonTapped$.bind{[weak self] reason in
            self?.createReport(reason: reason)
        }.disposed(by: disposeBag)
        
        
        return Output(isLoading$: isLoading$.asObservable(), isSuccess$: isSuccess$.asObservable(), networkError$: networkError$.asObservable(), clientError$: clientError$.asObservable(), reportType$: reportType$.asObservable())
    }
    
    private func createReport(reason:String?){
        
        guard let placeId = self.placeId else{
            clientError$.accept(.placeId)
            return;
        }
        
        
        guard let reportType = self.reportType$.value else{
            clientError$.accept(.placeType)
            return;
        }
        
        isLoading$.accept(true)
        Task{
            defer{
                isLoading$.accept(false)
            }
            let result = await self.placeUsecase?.createPlaceReport(placeId: placeId, reportType: reportType, reason: reason)
            
            switch(result){
            case .success:
                print("sucess")
                self.isSuccess$.accept(true)
            case.failure(let error):
                self.networkError$.accept(error);
            default:
                print("default")
            }
            
        }
    }
    
    public struct Output{
        let isLoading$: Observable<Bool>
        let isSuccess$:Observable<Bool?>
        let networkError$:Observable<NetworkError?>
        let clientError$:Observable<ReportClientError?>
        
        let reportType$: Observable<PlaceReportType?>
    }
    
    public struct Input{
        let cancelButttonTapped$: Observable<Void>
        let placeTypeCellTapped$: Observable<PlaceReportType>
        let confirmButtonTapped$: Observable<String>
    }
    
}


