//
//  SimpleMenuTableViewCell.swift
//  BibleAtlas
//
//  Created by 배성연 on 7/18/25.
//

import UIKit

enum SimpleMenuId {
    case navigateCS
    case navigatePROFILE
    case logout
    case withdrawal
}


struct SimpleMenuItem {
    var id: SimpleMenuId
    var nameText:String
    var isMovable: Bool
    var textColor: UIColor?
}


final class SimpleMenuTableViewCell: UITableViewCell {
    
    static let identifier = "simpleMenuCell"
    
    private lazy var stackView = {
        
        let sv = UIStackView(arrangedSubviews: [nameLabel, arrowIcon])
            
        sv.axis = .horizontal;
        sv.distribution = .fillProportionally;
        sv.alignment = .center;
        
        return sv;
    }()
        
        
    private let nameLabel = {
        let label = UILabel();
        label.font = .systemFont(ofSize: 16, weight: .medium)
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
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview()
                .inset(30)
        }
    }
    
    func setMenu(menuItem:SimpleMenuItem){
        nameLabel.text = menuItem.nameText;
        arrowIcon.isHidden = !menuItem.isMovable
        
        guard let textColor = menuItem.textColor else {
            return;
        }
        
        nameLabel.textColor = textColor
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}


#if DEBUG
extension SimpleMenuTableViewCell {
    var _test_nameLabel: UILabel { nameLabel }
    var _test_arrowIcon: UIImageView { arrowIcon }
    var _test_stackView: UIStackView { stackView }
}
#endif
