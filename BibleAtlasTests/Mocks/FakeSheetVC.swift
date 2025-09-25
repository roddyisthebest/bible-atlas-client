//
//  FakeSheetVC.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/25/25.
//

import UIKit
@testable import BibleAtlas
final class FakeSheetVC: UIViewController {
    let tag: String
    init(_ tag: String) {
        self.tag = tag
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        view.backgroundColor = .white
    }
    required init?(coder: NSCoder) { fatalError() }
}

final class FakePlaceDetailVC: UIViewController, IdentifiableBottomSheet {
    let placeId: String
    var bottomSheetIdentity: BottomSheetType { .placeDetail(placeId) }
    init(placeId: String) {
        self.placeId = placeId
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        view.backgroundColor = .white
    }
    required init?(coder: NSCoder) { fatalError() }
}
