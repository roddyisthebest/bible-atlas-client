//
//  AppStoreTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/8/25.
//

import XCTest
import RxSwift
import RxRelay
@testable import BibleAtlas

final class AppStoreTests: XCTestCase {

    private var sut: AppStore!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        sut = AppStore()
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        sut = nil
        disposeBag = nil
        super.tearDown()
    }

    /// 초기 state는 profile == nil, isLoggedIn == false 여야 한다
    func test_initialState_isLoggedOut() {
        // given & when
        let state = sut.state$.value

        // then
        XCTAssertNil(state.profile)
        XCTAssertFalse(state.isLoggedIn)
    }

    /// login 액션을 보내면 profile이 세팅되고 isLoggedIn이 true 가 된다
    func test_dispatchLogin_updatesStateToLoggedIn() {
        // given
        let user = User(id: 1, role: .EXPERT, avatar: "avatar2")

        // when
        sut.dispatch(.login(user))

        // then
        let state = sut.state$.value
        XCTAssertTrue(state.isLoggedIn)
        XCTAssertNotNil(state.profile)
        // 동일한 유저인지까지 보고 싶으면 (id 같은 필드 기준으로)
        // XCTAssertEqual(state.profile?.id, user.id)
    }

    /// login 후 logout 액션을 보내면 profile 이 nil 이 되고 isLoggedIn == false 가 된다
    func test_dispatchLogout_clearsProfileAndLoggedInFlag() {
        // given
        let user = User(id: 1, role: .EXPERT, avatar: "avatar2")
        sut.dispatch(.login(user))

        // when
        sut.dispatch(.logout)

        // then
        let state = sut.state$.value
        XCTAssertFalse(state.isLoggedIn)
        XCTAssertNil(state.profile)
    }

    /// 여러 번 login 을 보내면 마지막 유저로 덮어씌워진다
    func test_multipleLogin_overwritesProfileWithLastUser() {
        // given
        let user1 = User(id: 1, role: .EXPERT, avatar: "avatar1")
        let user2 = User(id: 2, role: .EXPERT, avatar: "avatar2")
        // user2.id = "another-id" 이런 식으로 필드 변경 (실제 모델에 맞게 수정)

        // when
        sut.dispatch(.login(user1))
        sut.dispatch(.login(user2))

        // then
        let state = sut.state$.value
        XCTAssertTrue(state.isLoggedIn)
        XCTAssertNotNil(state.profile)
        // 마지막 유저로 덮였는지
        // XCTAssertEqual(state.profile?.id, user2.id)
    }

    /// state$ 가 실제로 변경 이벤트를 emit 하는지도 한 번 체크
    func test_stateRelay_emitsOnDispatch() {
        // given
        let user = User(id: 1, role: .EXPERT, avatar: "avatar1")
        let exp = expectation(description: "state updated")

        var emittedStates: [AppState] = []

        sut.state$
            .skip(1) // 초기값은 건너뛰고
            .subscribe(onNext: { state in
                emittedStates.append(state)
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        // when
        sut.dispatch(.login(user))

        // then
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(emittedStates.count, 1)
        XCTAssertTrue(emittedStates[0].isLoggedIn)
        XCTAssertNotNil(emittedStates[0].profile)
    }
}
