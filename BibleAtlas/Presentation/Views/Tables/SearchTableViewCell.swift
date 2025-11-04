//
//  SearchTableViewCell.swift
//  BibleAtlas
//
//  Created by 배성연 on 7/1/25.
//

import UIKit
import SnapKit

final class SearchTableViewCell: UITableViewCell {

    static let identifier = "searchTableCell"

    private let searchIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        iv.tintColor = .mainLabelText
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let searchLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .mainText
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        return label
    }()

    private let circleIcon: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 5, weight: .regular, scale: .medium)
        let iv = UIImageView(image: UIImage(systemName: "circle.fill", withConfiguration: config))
        iv.tintColor = .mainLabelText
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let typeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .mainLabelText
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
        setupStyle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(searchIcon)
        contentView.addSubview(searchLabel)
        contentView.addSubview(circleIcon)
        contentView.addSubview(typeLabel)
    }
    
    private func setupStyle(){
        contentView.backgroundColor = .mainBkg
    }

    private func setupConstraints() {
        let spacing = 8

        searchIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }

        searchLabel.snp.makeConstraints { make in
            make.leading.equalTo(searchIcon.snp.trailing).offset(spacing)
            make.centerY.equalToSuperview()
        }

        circleIcon.snp.makeConstraints { make in
            make.leading.equalTo(searchLabel.snp.trailing).offset(spacing)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(6)
        }

        typeLabel.snp.makeConstraints { make in
            make.leading.equalTo(circleIcon.snp.trailing).offset(spacing)
            make.trailing.lessThanOrEqualToSuperview()
            make.centerY.equalToSuperview()
        }
    }

    func setCotent(recentSearchItem: RecentSearchItem) {
        searchLabel.text = L10n.isEnglish ? recentSearchItem.name : recentSearchItem.koreanName
        let placeTypeName = PlaceTypeName(rawValue: recentSearchItem.type)
        typeLabel.text = L10n.isEnglish ? placeTypeName?.titleEn : placeTypeName?.titleKo
    }
}
