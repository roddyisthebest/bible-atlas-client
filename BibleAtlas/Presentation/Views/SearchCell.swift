//
//  SearchCell.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/19/25.
//

import UIKit
import SnapKit

class SearchCell: UITableViewCell {

    static let identifier = "SearchCell"

    private let globalIcon = {
        let imageView = UIImageView(image:UIImage(systemName: "globe.asia.australia.fill"));
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .primaryViolet;
        return imageView;
    }()
    
    private let keywordLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 15)
        label.textColor = .white;
        label.text = "코리치안스"
        return label
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
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    private func setupUI(){
        contentView.backgroundColor = .backgroundDark
        contentView.addSubview(globalIcon);
        contentView.addSubview(keywordLabel)
    }
    
    private func setupConstraints(){
        globalIcon.snp.makeConstraints{make in
            make.width.height.equalTo(30);
            make.leading.equalToSuperview().offset(20);
            make.centerY.equalToSuperview()
        }
        
        keywordLabel.snp.makeConstraints{make in
            make.centerY.equalToSuperview();
            make.trailing.equalToSuperview().inset(20);
            make.leading.equalTo(globalIcon.snp.trailing).offset(20)
        }
        
        
    }
    
    func configure(keyword:String?){
        keywordLabel.text = keyword
    }

}
