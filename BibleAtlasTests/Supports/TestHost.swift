//
//  TestHost.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/25/25.
//

import XCTest
import UIKit
@testable import BibleAtlas

/// 런루프 펌프: 애니메이션/시트 상태 반영용
@discardableResult
public func pump(_ seconds: TimeInterval = 0.0) -> Bool {
    let until = Date().addingTimeInterval(seconds)
    RunLoop.main.run(until: until)
    return true
}

/// 간단한 XCTestExpectation 헬퍼
@inline(__always)
public func expect(_ desc: String) -> XCTestExpectation { .init(description: desc) }

/// 테스트용 호스트 윈도우 + 루트 VC
/// - 실제 present/dismiss 사용 → sheetPresentationController 생성/변화 확인 가능
public final class TestHost {
    public let window: UIWindow
    public let root: UIViewController

    public init(frame: CGRect = UIScreen.main.bounds,
                root: UIViewController = UIViewController()) {
        self.window = UIWindow(frame: frame)
        self.root = root
        window.rootViewController = root
        window.makeKeyAndVisible()
        // 초기 레이아웃 한 번 돌려주기
        pump(0.01)
    }

    /// 모달 프레젠트(동기 대기)
    @discardableResult
    public func present(_ vc: UIViewController,
                        animated: Bool = false,
                        timeout: TimeInterval = 2.0) -> UIViewController {
        let exp = expect("present")
        root.present(vc, animated: animated) { exp.fulfill() }
        XCTWaiter().wait(for: [exp], timeout: timeout)
        pump(0.02)
        return vc
    }

    /// 최상단 VC 기준으로 모달 프레젠트(동기 대기)
    @discardableResult
    public func presentOnTop(_ vc: UIViewController,
                             animated: Bool = false,
                             timeout: TimeInterval = 2.0) -> UIViewController {
        let exp = expect("presentOnTop")
        topMost.present(vc, animated: animated) { exp.fulfill() }
        XCTWaiter().wait(for: [exp], timeout: timeout)
        pump(0.02)
        return vc
    }

    /// 최상단 VC에서 dismiss(동기 대기)
    public func dismissTop(animated: Bool = false, timeout: TimeInterval = 2.0) {
        guard let presented = topMost.presentedViewController else { return }
        let exp = expect("dismissTop")
        presented.dismiss(animated: animated) { exp.fulfill() }
        XCTWaiter().wait(for: [exp], timeout: timeout)
        pump(0.02)
    }

    /// 최상단 VC
    public var topMost: UIViewController {
        var node = root
        while let next = node.presentedViewController { node = next }
        return node
    }
}

/// sheetPresentationController 편의 접근
public extension UIViewController {
    var sheet: UISheetPresentationController? { sheetPresentationController }
}
