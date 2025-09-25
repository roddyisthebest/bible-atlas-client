//
//  MockPresenter.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/25/25.
//

import UIKit
@testable import BibleAtlas

/// 테스트에서 코디네이터가 사용할 실제 presenter VC
final class PresenterHostVC: UIViewController, Presentable {
    // 코디네이터가 요구하는 Presentable API를 UIKit에 연결
    func present(vc: ViewController, animated: Bool) {
        self.present(vc, animated: animated, completion: nil)
    }

    func dismiss(animated: Bool) {
        self.dismiss(animated: animated, completion: nil)
    }

}
