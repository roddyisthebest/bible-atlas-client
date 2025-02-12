//
//  AccountSettingCell.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/12/25.
//

import UIKit
import SnapKit

class AccountSettingCell: UITableViewCell {
    static let identifier = "AccountSettingsCell"
    
    private let titleLabel:UILabel = {
        let label = UILabel();
        label.font = .systemFont(ofSize: 16);
        label.textColor = .white;
        return label
    }();
    
    private let detailLabel:UILabel = {
        let label = UILabel();
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .white
        return label;
    }()
    
    private let arrowImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI();
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    private func setupUI() {
        backgroundColor = .clear
        contentView.addSubview(titleLabel)
        contentView.addSubview(detailLabel)
        contentView.addSubview(arrowImageView)
    }
    
    
    private func setupConstraints(){
        titleLabel.snp.makeConstraints{ make in
            make.leading.equalToSuperview().offset(15)
            make.centerY.equalToSuperview()
        }
        
        detailLabel.snp.makeConstraints{ make in
            make.trailing.equalToSuperview().inset(15)
            make.centerY.equalToSuperview()
        }
        
        arrowImageView.snp.makeConstraints{ make in
            make.trailing.equalToSuperview().inset(15);
            make.centerY.equalToSuperview()
            make.width.height.equalTo(15)
        }
    }
    
    

    func configure(title: String, showArrow: Bool, detailText: String? = nil, isDestructive: Bool = false){
        titleLabel.text = title;
        
        arrowImageView.isHidden = !showArrow;
        
        detailLabel.text = detailText;
        detailLabel.isHidden = detailText == nil;
        
        if isDestructive {
            titleLabel.textColor = .red
        }
    }
    
    
    
}
