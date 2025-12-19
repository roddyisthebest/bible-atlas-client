//
//  MockLoginBottomSheetViewModel.swift
//  BibleAtlasTests
//
import RxSwift
import RxRelay
@testable import BibleAtlas

final class MockLoginBottomSheetViewModel: LoginBottomSheetViewModelProtocol {

    // transform 호출 횟수 추적
    private(set) var transformCallCount = 0

    // local 로그인으로 들어온 값들
    private(set) var receivedLocalLoginTuples: [(String?, String?)] = []

    // close 버튼 탭 횟수
    private(set) var closeButtonTapCount = 0

    // 출력 스트림들
    let errorSubject = PublishSubject<NetworkError>()
    let googleLoadingRelay = BehaviorRelay<Bool>(value: false)
    let appleLoadingRelay = BehaviorRelay<Bool>(value: false)
    let localLoadingRelay = BehaviorRelay<Bool>(value: false)

    private let disposeBag = DisposeBag()

    func transform(input: LoginBottomSheetViewModel.Input) -> LoginBottomSheetViewModel.Output {
        transformCallCount += 1

        // local 로그인 값 추적
        input.localLoginButtonTapped$
            .subscribe(onNext: { [weak self] tuple in
                self?.receivedLocalLoginTuples.append(tuple)
            })
            .disposed(by: disposeBag)

        // close 버튼 탭 횟수 추적
        input.closeButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.closeButtonTapCount += 1
            })
            .disposed(by: disposeBag)

        // 나머지(googleToken, appleToken)는 이번 테스트에선 사용 안 해도 됨

        return LoginBottomSheetViewModel.Output(
            error$: errorSubject.asObservable(),
            googleLoading$: googleLoadingRelay.asObservable(),
            appleLoading$: appleLoadingRelay.asObservable(),
            localLoading$: localLoadingRelay.asObservable()
        )
    }
}
