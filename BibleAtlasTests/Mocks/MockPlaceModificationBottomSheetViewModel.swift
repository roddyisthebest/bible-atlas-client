// MyCollectionTests/Mocks/MockPlaceModificationBottomSheetViewModel.swift
@testable import BibleAtlas
import RxSwift
import RxRelay

final class MockPlaceModificationBottomSheetViewModel: PlaceModificationBottomSheetViewModelProtocol {
    
    private let disposeBag = DisposeBag()
    
    // transform 호출 여부
    private(set) var transformCalled = false
    
    // 입력 캡처
    private(set) var cancelTapCount = 0
    private(set) var confirmTapCount = 0
    
    // 출력 스트림 제어용 Subject
    let interactionErrorSubject = PublishSubject<NetworkError?>()
    let isCreatingSubject = PublishSubject<Bool>()
    let isSuccessSubject = PublishSubject<Bool?>()
    
    func transform(input: PlaceModificationBottomSheetViewModel.Input) -> PlaceModificationBottomSheetViewModel.Output {
        transformCalled = true
        
        input.cancelButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.cancelTapCount += 1
            })
            .disposed(by: disposeBag)
        
        input.confirmButtonTapped$
            .subscribe(onNext: { [weak self] comment in
                self?.confirmTapCount += 1
            })
            .disposed(by: disposeBag)
        
        return PlaceModificationBottomSheetViewModel.Output(
            interactionError$: interactionErrorSubject.asObservable(),
            isCreating$: isCreatingSubject.asObservable(),
            isSuccess$: isSuccessSubject.asObservable()
        )
    }
}
