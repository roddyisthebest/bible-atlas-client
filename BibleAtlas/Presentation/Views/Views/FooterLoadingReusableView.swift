//
//  FooterLoadingReusableView.swift
//  BibleAtlas
//
//  Created by 배성연 on 6/1/25.
//

import UIKit

final class FooterLoadingReusableView: UICollectionReusableView {
    static let identifier = "FooterLoadingReusableView"

    private let loadingView = LoadingView(style: .medium)

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(loadingView)
        loadingView.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func start() {
        loadingView.start()
    }

    func stop() {
        loadingView.stop()
    }
}
