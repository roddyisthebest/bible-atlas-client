//
//  RxNotificationServiceTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/26/25.
//

import XCTest
import RxSwift
import RxCocoa

@testable import BibleAtlas

final class RxNotificationServiceTests: XCTestCase {

    private var sut: RxNotificationService!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        sut = RxNotificationService()
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        disposeBag = nil
        sut = nil
        super.tearDown()
    }

    func test_post_emitsNotificationToObservers_withObject() {
        // given
        let name = Notification.Name("testNotification")
        let expectedObject = "payload"

        let exp = expectation(description: "notification received")
        var capturedObject: Any?

        sut.observe(name)
            .take(1)
            .subscribe(onNext: { notification in
                capturedObject = notification.object
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        // when
        sut.post(name, object: expectedObject)

        // then
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(capturedObject as? String, expectedObject)
    }

    func test_observe_doesNotReceiveDifferentNotificationName() {
        // given
        let targetName = Notification.Name("targetNotification")
        let otherName = Notification.Name("otherNotification")

        let exp = expectation(description: "should not receive other notification")
        exp.isInverted = true  // 🔥 이 expectation 이 fulfill 되면 실패

        sut.observe(targetName)
            .subscribe(onNext: { _ in
                exp.fulfill()   // 이게 불리면 안 됨
            })
            .disposed(by: disposeBag)

        // when
        sut.post(otherName, object: nil)

        // then
        wait(for: [exp], timeout: 0.5)
    }
}
