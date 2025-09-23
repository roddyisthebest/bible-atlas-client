//
//  BibleBookCell.swift
//  BibleAtlas
//
//  Created by 배성연 on 9/23/25.
//

import UIKit

import UIKit

class BibleBookCell: UICollectionViewCell {
    static let identifier = "bibleBookCell"
    
    private lazy var containerStackView = {
        let sv = UIStackView(arrangedSubviews: [iconWrapper, nameLabel, numberLabel]);
        sv.axis = .vertical;
        sv.distribution = .fill;
        sv.alignment = .center;
        sv.spacing = 5;
        contentView.addSubview(sv)
        return sv;
    }()
    
    private lazy var iconWrapper = {
        let v = UIView();
        v.backgroundColor = .placeCircle;
        v.layer.cornerRadius = 25;
        v.layer.masksToBounds = true;
        v.addSubview(bibleBookLabel)
        return v;
    }()
    
    private let bibleBookLabel:UILabel = {
        let label = UILabel();
        label.textColor = .mainText;
        label.font = .boldSystemFont(ofSize: 20)
        return label;
    }()
    
    private let nameLabel = {
        let label = UILabel();
        label.text = "Water of Body"
        label.textColor = .mainText
        label.numberOfLines = 1;
        label.font = .boldSystemFont(ofSize: 16)
        label.lineBreakMode = .byTruncatingTail
        return label;
    }()
    
    
    private let numberLabel = {
        let label = UILabel();
        label.textColor = .placeDescriptionText;
        label.numberOfLines = 1;
        label.lineBreakMode = .byTruncatingTail
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.text = "12 places"
        return label;
    }()
    
  
    
    
    func setBibleBook(bibleBookCount:BibleBookCount){
        nameLabel.text = bibleBookCount.bible;
        
        let twoChars = String(bibleBookCount.bible
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(2))
        bibleBookLabel.text = twoChars
        numberLabel.text =  "\(bibleBookCount.placeCount) Places"
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
        
        bibleBookLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    
}
