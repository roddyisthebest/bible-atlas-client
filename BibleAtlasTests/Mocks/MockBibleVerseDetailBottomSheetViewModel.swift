//
//  MockBibleVerseDetailBottomSheetViewModel.swift
//  BibleAtlasTests
//

import Foundation
import RxSwift
import RxRelay
@testable import BibleAtlas

final class MockBibleVerseDetailBottomSheetViewModel: BibleVerseDetailBottomSheetViewModelProtocol {

    // MARK: - Outputs 흉내낼 Relay
    let bibleVerseRelay = BehaviorRelay<String>(value: "")
    let errorRelay = BehaviorRelay<NetworkError?>(value: nil)
    let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    let titleRelay = BehaviorRelay<String?>(value: nil)
    let placeNameRelay = BehaviorRelay<String?>(value: nil)

    // MARK: - Input tracking
    private(set) var viewLoadedCallCount = 0
    private(set) var refetchButtonTapCount = 0
    private(set) var closeButtonTapCount = 0

    private let disposeBag = DisposeBag()

    func transform(input: BibleVerseDetailBottomSheetViewModel.Input) -> BibleVerseDetailBottomSheetViewModel.Output {

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

        input.closeButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.closeButtonTapCount += 1
            })
            .disposed(by: disposeBag)

        return BibleVerseDetailBottomSheetViewModel.Output(
            bibleVerse$: bibleVerseRelay.asObservable(),
            error$: errorRelay.asObservable(),
            isLoading$: isLoadingRelay.asObservable(),
            title$: titleRelay.asObservable(),
            placeName$: placeNameRelay.asObservable()
        )
    }
}
