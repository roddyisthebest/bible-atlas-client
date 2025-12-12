//
//  MockMyPageBottomSheetViewModel.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/??/25.
//

import XCTest
import RxSwift
import RxRelay
@testable import BibleAtlas

// MARK: - Mock ViewModel for VC tests

// 대충 이런 모양일 거라고 가정
final class MockMyPageBottomSheetViewModel: MyPageBottomSheetViewModelProtocol {

    let menuItems: [MenuItem]

    var transformCallCount = 0
    var receivedMenuItemTaps: [MenuItem] = []
    var receivedCloseEvents = 0

    private let profileSubject = PublishSubject<User?>()

    init(menuItems: [MenuItem]) {
        self.menuItems = menuItems
    }

    func transform(input: MyPageBottomSheetViewModel.Input) -> MyPageBottomSheetViewModel.Output {
        transformCallCount += 1

        input.closeButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.receivedCloseEvents += 1
            })
            .disposed(by: disposeBag)

        input.menuItemCellTapped$
            .subscribe(onNext: { [weak self] item in
                self?.receivedMenuItemTaps.append(item)
            })
            .disposed(by: disposeBag)

        return .init(
            profile$: profileSubject.asObservable()
        )
    }

    // 테스트에서 profile 이벤트를 쏴주기 위한 헬퍼
    func emitProfile(_ user: User?) {
        profileSubject.onNext(user)
    }

    private let disposeBag = DisposeBag()
}
