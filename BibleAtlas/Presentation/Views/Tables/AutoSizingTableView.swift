//
//  AutoSizingTableView.swift
//  BibleAtlas
//
//  Created by 배성연 on 9/29/25.
//

import UIKit

final class AutoSizingTableView: UITableView {
    override var contentSize: CGSize {
        didSet { invalidateIntrinsicContentSize() }
    }
    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}
