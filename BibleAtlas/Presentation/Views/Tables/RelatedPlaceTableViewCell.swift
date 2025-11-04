//
//  RelatedPlaceTableViewCell.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/10/25.
//

import UIKit

class RelatedPlaceTableViewCell: UITableViewCell {
    
    static let identifier = "relatedPlaceCell"

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
    
    private let placeIcon:UIImageView = {
        let icon = UIImageView(image: UIImage(named: "ground"));
        return icon;
    }()
    
    
    private lazy var contentStackView:UIStackView = {
        let sv = UIStackView(arrangedSubviews: [titleContainer, descriptionLabel]);
        sv.axis = .vertical;
        sv.spacing = 4;
        sv.alignment = .fill;
        sv.distribution = .fillEqually;
        return sv;
    }()
    
    
    private lazy var titleContainer = {
        let v = UIView();
        v.addSubview(titleLabel);
        v.addSubview(stereoBadge)
        v.addSubview(percentBadge)

        
        return v;
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 17)
        label.textColor = .mainText
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.text = "정말 정말 긴 "
        return label
    }()
    
    private let percentBadge: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("100%", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        button.backgroundColor = .badge100
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.isUserInteractionEnabled = false
        return button
    }()
    
    private let stereoBadge: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(L10n.PlaceDetail.ancient, for: .normal)
        button.setTitleColor(.ancientBadgeText, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        button.backgroundColor = .ancientBadgeBkg
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true

        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8) // ✅ 내부 패딩


        return button
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
        
  
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
        
        stereoBadge.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(5)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
            make.height.equalTo(20)
        }
        
        percentBadge.snp.makeConstraints { make in
            make.leading.equalTo(stereoBadge.snp.trailing).offset(5)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
            make.width.equalTo(40)
            make.height.equalTo(20)
        }
        
        // ✅ 우선순위: titleLabel이 가장 먼저 줄어들도록
         titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
         titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

         // ✅ 배지는 가급적 유지되도록 (높은 우선순위)
         stereoBadge.setContentCompressionResistancePriority(.required, for: .horizontal)
         stereoBadge.setContentHuggingPriority(.required, for: .horizontal)
         percentBadge.setContentCompressionResistancePriority(.required, for: .horizontal)
         percentBadge.setContentHuggingPriority(.required, for: .horizontal)
        
        
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
        titleLabel.text = text
    }
    
    func setPercentageBadge(relation:PlaceRelation){
        percentBadge.setTitle("\(relation.possibility)%", for: .normal)
        
        switch(relation.possibility){
            case 100:
                percentBadge.backgroundColor = .badge100
                return
           case 70...99:
                percentBadge.backgroundColor = .badge90to70
                return
           case 40...69:
                percentBadge.backgroundColor = .badge60to40
                return
           default:
                percentBadge.backgroundColor = .badge30to0
                return
           }

    }
    
    func setStereoBadge(relation:PlaceRelation){
        if(relation.place.isModern){
            stereoBadge.backgroundColor = .modernBadgeBkg
            stereoBadge.setTitleColor(.modernBadgeText, for: .normal)
            stereoBadge.setTitle(L10n.PlaceDetail.modern, for: .normal)
        }
        else{
            stereoBadge.backgroundColor = .ancientBadgeBkg
            stereoBadge.setTitleColor(.ancientBadgeText, for: .normal)
            stereoBadge.setTitle(L10n.PlaceDetail.ancient, for: .normal)

        }
    }
    
    func setRelation(relation:PlaceRelation){
        
        titleLabel.text = L10n.isEnglish ? relation.place.name: relation.place.koreanName;
        descriptionLabel.text = L10n.isEnglish ? relation.place.description : relation.place.koreanDescription;
        
        setPercentageBadge(relation: relation)
        setStereoBadge(relation: relation)
        
        
        guard let placeType = relation.place.types.first else {
            placeIcon.image = UIImage(named: "ground");
            return;
        }
        
        placeIcon.image = UIImage(named: placeType.name.rawValue)
        
        
    }

}
