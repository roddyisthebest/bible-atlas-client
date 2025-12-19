//
//  MockAccountManagementBottomSheetViewModel.swift
//  BibleAtlasTests
//

import Foundation
import RxSwift
import RxRelay
@testable import BibleAtlas

final class MockAccountManagementBottomSheetViewModel: AccountManagementBottomSheetViewModelProtocol {

    // MARK: - Outputs를 흉내낼 Subject들
    let errorSubject = PublishSubject<NetworkError?>()
    let isWithdrawingSubject = PublishSubject<Bool>()
    let showWithdrawConfirmSubject = PublishSubject<Void>()
    let showWithdrawCompleteSubject = PublishSubject<Void>()

    private let disposeBag = DisposeBag()

    // MARK: - 입력 추적용
    private(set) var receivedCloseTapCount = 0
    private(set) var receivedMenuItems: [SimpleMenuItem] = []
    private(set) var receivedWithdrawConfirmTapCount = 0
    private(set) var receivedWithdrawCompleteConfirmTapCount = 0

    // MARK: - 메뉴 아이템 (VC에서 테이블 렌더링용)
    let menuItems: [SimpleMenuItem]

    init(menuItems: [SimpleMenuItem]? = nil) {
        self.menuItems = menuItems ?? [
            SimpleMenuItem(id: .navigateCS,   nameText: "고객센터", isMovable: true),
            SimpleMenuItem(id: .logout,       nameText: "로그아웃", isMovable: false),
            SimpleMenuItem(id: .withdrawal,   nameText: "탈퇴",     isMovable: false)
        ]
    }

    func transform(input: AccountManagementBottomSheetViewModel.Input) -> AccountManagementBottomSheetViewModel.Output {

        input.closeButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.receivedCloseTapCount += 1
            })
            .disposed(by: disposeBag)

        input.menuItemCellTapped$
            .subscribe(onNext: { [weak self] item in
                self?.receivedMenuItems.append(item)
            })
            .disposed(by: disposeBag)

        input.withdrawConfirmButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.receivedWithdrawConfirmTapCount += 1
            })
            .disposed(by: disposeBag)

        input.withdrawCompleteConfirmButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.receivedWithdrawCompleteConfirmTapCount += 1
            })
            .disposed(by: disposeBag)

        return AccountManagementBottomSheetViewModel.Output(
            error$: errorSubject.asObservable(),
            isWithdrawing$: isWithdrawingSubject.asObservable(),
            showWithdrawConfirm$: showWithdrawConfirmSubject.asObservable(),
            showWithdrawComplete$: showWithdrawCompleteSubject.asObservable()
        )
    }
}
