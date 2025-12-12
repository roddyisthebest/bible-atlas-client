//
//  MockMemoBottomSheetViewModel.swift
//  BibleAtlasTests
//

import Foundation
import RxSwift
import RxRelay
@testable import BibleAtlas

final class MockMemoBottomSheetViewModel: MemoBottomSheetViewModelProtocol {

    // MARK: - Output Subjects (VC에서 구독)

    let memoSubject = BehaviorSubject<String>(value: "")
    let loadErrorSubject = BehaviorRelay<NetworkError?>(value: nil)
    let interactionErrorSubject = BehaviorRelay<NetworkError?>(value: nil)
    let isLoadingSubject = BehaviorSubject<Bool>(value: false)
    let isCreatingOrUpdatingSubject = BehaviorSubject<Bool>(value: false)
    let isDeletingSubject = BehaviorSubject<Bool>(value: false)

    private let disposeBag = DisposeBag()

    // MARK: - Input Tracking

    private(set) var viewLoadedCallCount = 0
    private(set) var refetchButtonTapCount = 0
    private(set) var cancelButtonTapCount = 0
    private(set) var confirmButtonTapTexts: [String] = []
    private(set) var deleteButtonTapCount = 0

    func transform(input: MemoBottomSheetViewModel.Input) -> MemoBottomSheetViewModel.Output {

        input.viewLoaded$
            .subscribe(onNext: { [weak self] in
                self?.viewLoadedCallCount += 1
            })
            .disposed(by: disposeBag)

        input.refetchButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.refetchButtonTapCount += 1
            })
            .disposed(by: disposeBag)

        input.cancelButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.cancelButtonTapCount += 1
            })
            .disposed(by: disposeBag)

        input.confirmButtonTapped$
            .subscribe(onNext: { [weak self] text in
                self?.confirmButtonTapTexts.append(text)
            })
            .disposed(by: disposeBag)

        input.deleteButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.deleteButtonTapCount += 1
            })
            .disposed(by: disposeBag)

        return MemoBottomSheetViewModel.Output(
            memo$: memoSubject.asObservable(),
            loadError$: loadErrorSubject.asObservable(),
            interactionError$: interactionErrorSubject.asObservable(),
            isLoading$: isLoadingSubject.asObservable(),
            isCreatingOrUpdating$: isCreatingOrUpdatingSubject.asObservable(),
            isDeleting$: isDeletingSubject.asObservable()
        )
    }
}
