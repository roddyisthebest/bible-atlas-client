//
//  MenuTableViewCell.swift
//  BibleAtlas
//
//  Created by 배성연 on 7/17/25.
//

import UIKit


struct MenuItem {
    var nameText:String
    var iconImage:String
    var iconBackground: UIColor
    var contentText:String?
    var bottomSheetType:BottomSheetType?
}


final class MenuTableViewCell: UITableViewCell {
    static let identifier = "menuCell"
    
    let iconWrapperLength = 30

    
    private lazy var stackView = {
        let sv = UIStackView(arrangedSubviews: [titleStackView, ]);
        
        sv.axis = .horizontal
        sv.distribution = .fillProportionally;
        sv.alignment = .center
        
        return sv;
    }()
    
    
    private lazy var titleStackView = {
        let sv = UIStackView(arrangedSubviews: [iconWrapper, nameLabel])
        sv.axis = .horizontal
        sv.distribution = .fill
        sv.spacing = 8
        sv.alignment = .center
    
        return sv;
    }()
    
    
    private lazy var iconWrapper:UIView = {
        let v = UIView();
        v.layer.cornerRadius = CGFloat(iconWrapperLength / 2)
        v.layer.masksToBounds = true
        
        v.addSubview(icon)
        return v;
    }()
    
    
    private let icon: UIImageView = {
        let icon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        icon.tintColor = .invertedMainText
        icon.contentMode = .scaleAspectFit
    
        return icon
    }()
    
    private let nameLabel:UILabel = {
        let label = UILabel();
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .mainText
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private let arrowIcon:UIImageView = {
        let icon = UIImageView(image: UIImage(systemName: "chevron.right"))
        icon.tintColor = .mainText
        icon.contentMode = .right
        return icon
    }()
    
    private let contentLabel:UILabel = {
        let label = UILabel();
        label.font = .boldSystemFont(ofSize: 14)
        label.textColor = .mainText
        label.textAlignment = .right
        return label
    }()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    

    
    private func setupUI(){
        contentView.addSubview(stackView)
    }
    
    
    
    private func setupConstraints(){
        stackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview()
                .inset(30)
            
            make.top.bottom.equalToSuperview()
        }
        
        iconWrapper.snp.makeConstraints { make in
            make.width.height.equalTo(iconWrapperLength)
        }
        
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview();
            make.width.height.equalTo(Double(iconWrapperLength) * 0.6)
        }
    }
    
    
    func setMenu(menuItem:MenuItem){
        
        nameLabel.text = menuItem.nameText;
        icon.image = UIImage(systemName: menuItem.iconImage);
        iconWrapper.backgroundColor = menuItem.iconBackground
        
        guard let contentText = menuItem.contentText else {
            stackView.addArrangedSubview(arrowIcon)
            return
        }
        
        stackView.addArrangedSubview(contentLabel)
        contentLabel.text = contentText
        
    }
    
  

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
