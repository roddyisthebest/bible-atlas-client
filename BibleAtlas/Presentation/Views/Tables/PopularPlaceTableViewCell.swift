//
//  PopularPlaceTableViewCell.swift
//  BibleAtlas
//
//  Created by 배성연 on 7/5/25.
//

import UIKit

class PopularPlaceTableViewCell: UITableViewCell {
    
    static let identifier = "popularPlaceTableCell"

    private lazy var iconWrapper: UIView = {
        let v = UIView();
        v.backgroundColor = .placeCircle;
        v.layer.cornerRadius = 14;
        v.layer.masksToBounds = true;
        v.addSubview(placeIcon)
        return v;
    }()
    
    private lazy var placeIcon: UIImageView = {
        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        return icon
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

    private let likeLabel: UILabel = {
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
        contentView.addSubview(iconWrapper)
        contentView.addSubview(searchLabel)
        contentView.addSubview(circleIcon)
        contentView.addSubview(likeLabel)
    }
    
    private func setupStyle(){
        contentView.backgroundColor = .mainBkg
    }

    private func setupConstraints() {
        let spacing = 8

        iconWrapper.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(28)
        }

        searchLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconWrapper.snp.trailing).offset(spacing)
            make.centerY.equalToSuperview()
        }

        circleIcon.snp.makeConstraints { make in
            make.leading.equalTo(searchLabel.snp.trailing).offset(spacing)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(6)
        }

        likeLabel.snp.makeConstraints { make in
            make.leading.equalTo(circleIcon.snp.trailing).offset(spacing)
            make.trailing.lessThanOrEqualToSuperview()
            make.centerY.equalToSuperview()
        }
        
        placeIcon.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.center.equalToSuperview()
        }
    }

    func setCotent(place: Place) {
        searchLabel.text = place.name
        likeLabel.text = "\(place.likeCount) likes"
        
        let hasOneType = place.types.count == 1;
        
        if(hasOneType){
            let placeType = place.types[0];
            placeIcon.image = UIImage(named: placeType.name.rawValue)
            
            return;
        }
        
        placeIcon.image = UIImage(named: "ground");
        
    }
}

#if DEBUG
extension PopularPlaceTableViewCell {
    var _test_searchLabel: UILabel { searchLabel }
    var _test_likeLabel: UILabel { likeLabel }
    var _test_placeIcon: UIImageView { placeIcon }
}
#endif
