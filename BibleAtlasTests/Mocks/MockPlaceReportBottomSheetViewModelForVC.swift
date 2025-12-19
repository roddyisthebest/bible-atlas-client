//
//  MockPlaceReportBottomSheetViewModelForVC.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/6/25.
//

import Foundation
import RxSwift
import RxRelay
@testable import BibleAtlas

final class MockPlaceReportBottomSheetViewModelForVC: PlaceReportBottomSheetViewModelProtocol {

    // Input 이벤트를 받는 subject (VC → VM)
    private(set) var cancelEvents: [Void] = []
    private(set) var receivedReportTypes: [PlaceReportType] = []
    private(set) var receivedConfirmReasons: [String] = []

    // Output 스트림 (VM → VC)
    let reportTypeSubject = BehaviorSubject<PlaceReportType?>(value: nil)
    let isLoadingSubject = BehaviorSubject<Bool>(value: false)
    let isSuccessSubject = BehaviorSubject<Bool?>(value: nil)
    let networkErrorSubject = BehaviorSubject<NetworkError?>(value: nil)
    let clientErrorSubject = BehaviorSubject<PlaceReportClientError?>(value: nil)

    private let disposeBag = DisposeBag()

    func transform(input: PlaceReportBottomSheetViewModel.Input)
        -> PlaceReportBottomSheetViewModel.Output {

        // VC에서 오는 cancel 버튼 탭 이벤트 기록
        input.cancelButttonTapped$
            .subscribe(onNext: { [weak self] in
                self?.cancelEvents.append(())
            })
            .disposed(by: disposeBag)

        // VC에서 오는 reportType cell 탭 이벤트 기록
        input.placeTypeCellTapped$
            .subscribe(onNext: { [weak self] type in
                self?.receivedReportTypes.append(type)
                // 실제 VM처럼 현재 선택 타입을 흉내내 주면 VC도 반응함
                self?.reportTypeSubject.onNext(type)
            })
            .disposed(by: disposeBag)

        // VC에서 오는 confirm(reason) 이벤트 기록
        input.confirmButtonTapped$
            .subscribe(onNext: { [weak self] reason in
                self?.receivedConfirmReasons.append(reason)
            })
            .disposed(by: disposeBag)

        return PlaceReportBottomSheetViewModel.Output(
            isLoading$: isLoadingSubject.asObservable(),
            isSuccess$: isSuccessSubject.asObservable(),
            networkError$: networkErrorSubject.asObservable(),
            clientError$: clientErrorSubject.asObservable(),
            reportType$: reportTypeSubject.asObservable()
        )
    }
}
