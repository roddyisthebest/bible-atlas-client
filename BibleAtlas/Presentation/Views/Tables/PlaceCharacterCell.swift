//
//  PlaceCharacterCell.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/11/25.
//

import UIKit

class PlaceCharacterCell: UICollectionViewCell {
    static let identifier = "placeCharacterCell";
    
    private var characterText:String? {
        didSet{
            characterLabel.text = characterText;
        }
    }
    
    
    private lazy var containerStackView = {
        let sv = UIStackView(arrangedSubviews: [iconWrapper, numberLabel]);
        sv.axis = .vertical;
        sv.distribution = .fill;
        sv.alignment = .center;
        sv.spacing = 0;
        contentView.addSubview(sv)
        return sv;
    }()
    
    private lazy var iconWrapper = {
        let v = UIView();
        v.backgroundColor = .placeCircle;
        v.layer.cornerRadius = 25;
        v.layer.masksToBounds = true;
        v.addSubview(characterLabel)
        return v;
    }()
    
    private let characterLabel:UILabel = {
        let label = UILabel();
        label.textColor = .mainText;
        label.font = .boldSystemFont(ofSize: 20)
        return label;
    }()
    
    
    private let numberLabel = {
        let label = UILabel();
        label.textColor = .mainText;
        label.numberOfLines = 1;
        label.lineBreakMode = .byTruncatingTail
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.text = "123 places"
        return label;
    }()
    
    func setPlaceCharacter(placeCharacter:PlacePrefix){
        characterLabel.text = placeCharacter.prefix.uppercased();
        numberLabel.text = "\(placeCharacter.placeCount) Places"
    }
    

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupConstraints()
    }
    
    private func setupConstraints(){
        
        containerStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10);
            make.trailing.equalToSuperview().inset(10);
            
            make.top.equalToSuperview().offset(20);
            make.bottom.equalToSuperview().inset(0);

        }
        
        
        iconWrapper.snp.makeConstraints { make in
            make.height.width.equalTo(50)
        }
        
        characterLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
}
