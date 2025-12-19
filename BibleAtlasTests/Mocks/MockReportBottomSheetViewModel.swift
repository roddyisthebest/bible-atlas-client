//
//  MockReportBottomSheetViewModel.swift
//  BibleAtlasTests
//

import Foundation
import RxSwift
import RxRelay
@testable import BibleAtlas

final class MockReportBottomSheetViewModel: ReportBottomSheetViewModelProtocol {
    
    // MARK: - Output Subjects (VC에서 구독)
    let interactionErrorSubject = PublishSubject<NetworkError?>()
    let isLoadingSubject = PublishSubject<Bool>()
    let isSuccessSubject = PublishSubject<Bool?>()
    
    // MARK: - Input tracking
    private(set) var receivedCancelTapCount = 0
    private(set) var receivedConfirmPayloads: [(String?, ReportType?)] = []
    
    private let disposeBag = DisposeBag()
    
    func transform(input: ReportBottomSheetViewModel.Input) -> ReportBottomSheetViewModel.Output {
        
        input.cancelButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.receivedCancelTapCount += 1
            })
            .disposed(by: disposeBag)
        
        input.confirmButtonTapped$
            .subscribe(onNext: { [weak self] tuple in
                self?.receivedConfirmPayloads.append(tuple)
            })
            .disposed(by: disposeBag)
        
        // viewLoaded$ 는 지금 테스트에서 딱히 안써도 됨
        input.viewLoaded$
            .subscribe()
            .disposed(by: disposeBag)
        
        return ReportBottomSheetViewModel.Output(
            interactionError$: interactionErrorSubject.asObservable(),
            isLoading$: isLoadingSubject.asObservable(),
            isSuccess$: isSuccessSubject.asObservable()
        )
    }
}
