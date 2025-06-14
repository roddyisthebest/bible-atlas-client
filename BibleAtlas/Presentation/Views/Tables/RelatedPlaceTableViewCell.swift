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
        button.backgroundColor = .oneHunnitPercentBadgeBkg
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.isUserInteractionEnabled = false
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
            make.width.height.equalTo(20)
        }
        
  
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
        
        percentBadge.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(5)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
            make.width.equalTo(40)
            make.height.equalTo(20)
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
        titleLabel.text = text
    }
    
    func setRelation(relation:ChildPlaceRelation){
        
        titleLabel.text = relation.child.name;
        descriptionLabel.text = relation.child.description;
        
        percentBadge.setTitle("\(relation.possibility)%", for: .normal)
        
        let hasOneType = relation.child.types.count == 1;

        if(hasOneType){
            let placeType = relation.child.types[0];
            placeIcon.image = UIImage(named: placeType.name.rawValue)
            
            return;
        }
        
        placeIcon.image = UIImage(named:"ground")
        
    }

}
