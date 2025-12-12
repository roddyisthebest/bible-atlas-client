//
//  FooterLoadingReusableViewTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/7/25.
//

import XCTest
@testable import BibleAtlas

final class FooterLoadingReusableViewTests: XCTestCase {

    private var sut: FooterLoadingReusableView!

    override func setUp() {
        super.setUp()
        sut = FooterLoadingReusableView(frame: .init(x: 0, y: 0, width: 100, height: 40))
        sut.layoutIfNeeded()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - 초기 설정 검증

    func test_init_addsLoadingViewAsSubview_andCentersIt() {
        // loadingView가 subview에 포함되어 있어야 함
        XCTAssertTrue(sut.subviews.contains(sut._test_loadingView))

        // SnapKit으로 center 제약을 줬으므로,
        // 레이아웃 이후 프레임의 중심이 부모와 비슷해야 함
        let parentCenter = CGPoint(x: sut.bounds.midX, y: sut.bounds.midY)
        let loadingCenter = CGPoint(x: sut._test_loadingView.frame.midX,
                                    y: sut._test_loadingView.frame.midY)

        XCTAssertEqual(parentCenter.x, loadingCenter.x, accuracy: 0.5)
        XCTAssertEqual(parentCenter.y, loadingCenter.y, accuracy: 0.5)
    }

    // MARK: - start / stop 이 정상 동작 (crash 없이 호출 가능)

    func test_startAndStop_doNotCrash() {
        // 그냥 호출만 해도 coverage + crash 방지 확인용
        sut.start()
        sut.stop()
        // 별도 assert 필요 X (크래시 안 나면 성공)
    }
}
