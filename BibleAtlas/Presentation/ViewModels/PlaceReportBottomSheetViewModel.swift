//
//  ReportBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 7/23/25.
//

import Foundation
import RxSwift
import RxRelay

protocol PlaceReportBottomSheetViewModelProtocol{
    func transform(input:PlaceReportBottomSheetViewModel.Input) -> PlaceReportBottomSheetViewModel.Output
}

enum PlaceReportClientError:Error{
    case placeId
    case placeType
    case reasonMissing
}

final class PlaceReportBottomSheetViewModel:PlaceReportBottomSheetViewModelProtocol{
        
    private let disposeBag = DisposeBag();
    
    private weak var navigator: BottomSheetNavigator?
    
    private var placeId:String? = nil
    
    private let reportType$ = BehaviorRelay<PlaceReportType?>(value:nil)
    
    private let isLoading$ = BehaviorRelay<Bool>(value: false)
    private let isSuccess$ = BehaviorRelay<Bool?>(value: nil)
    private let networkError$ = BehaviorRelay<NetworkError?>(value: nil)
    private let clientError$ = BehaviorRelay<PlaceReportClientError?>(value: nil)

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
        
        if reportType == .etc {
                // 1. reason이 nil이거나,
                // 2. reason이 있지만 공백/개행문자 제거 후 비어있는 경우 (isEmpty)
                
            guard let reason = reason else {
                clientError$.accept(.reasonMissing)
                return;
            }
            
            let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
                
            if trimmedReason.isEmpty {
                clientError$.accept(.reasonMissing)
                return
            }
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
        let clientError$:Observable<PlaceReportClientError?>
        
        let reportType$: Observable<PlaceReportType?>
    }
    
    public struct Input{
        let cancelButttonTapped$: Observable<Void>
        let placeTypeCellTapped$: Observable<PlaceReportType>
        let confirmButtonTapped$: Observable<String>
    }
    
}


