//
//  PlaceTableViewCell.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/26/25.
//

import UIKit

class PlaceTableViewCell: UITableViewCell {
    static let identifier = "placeCell"

    private lazy var containerStackView:UIStackView = {
        let sv = UIStackView(arrangedSubviews: [iconWrapper, contentStackView]);
        sv.axis = .horizontal
        sv.spacing = 14;
        sv.alignment = .center;
        sv.distribution = .fill;
        
        contentView.addSubview(sv)
        return sv;
    }()
    
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
    
    
    private lazy var contentStackView:UIStackView = {
        let sv = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel]);
        sv.axis = .vertical;
        sv.spacing = 0;
        sv.alignment = .fill;
        sv.distribution = .fillEqually;
        return sv;
    }()
    
    private let titleLabel = {
        let label = UILabel();
        
        label.text = "waterdfksldjfksljflsjfldsfjlsdfjkjdssdjfk";
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.textColor = .mainText;
        label.font = .boldSystemFont(ofSize: 17)
        return label;
    }()
    
    private let descriptionLabel = {
        let label = UILabel();
        
        label.text = "yyoyyoyyoaakkakakakkakakkakakakkakakakkakakakkakak";
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.textColor = .placeDescriptionText;
        label.font = .systemFont(ofSize: 14)

        return label;
    }()
    
    
    private func setupStyle(){
        containerStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }
        
        iconWrapper.snp.makeConstraints { make in
            make.width.height.equalTo(28)
        }
        
        placeIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalToSuperview()
        }
        
        backgroundColor = .mainItemBkg;
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupStyle();
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStyle();
    }
    
    
    func setText(text: String) {
        descriptionLabel.text = text
    }
    
    func setPlace(place:Place){
        
        titleLabel.text = L10n.isEnglish ? place.name: place.koreanName;
        descriptionLabel.text = L10n.isEnglish ? place.description: place.koreanDescription;

        guard let placeType = place.types.first else {
            placeIcon.image = UIImage(named: "ground");
            return;
        }
        
        placeIcon.image = UIImage(named: placeType.name.rawValue)

    }

}
