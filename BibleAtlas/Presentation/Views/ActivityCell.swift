//
//  ActivityCell.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/5/25.
//

import UIKit
import SnapKit

class ActivityCell: UITableViewCell {
        
    let view:UIView = {
        let view = UIView();
        return view;
    }()
    
    static let identifier = "ActivityCell"


    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupStyle();
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setupStyle(){
        contentView.backgroundColor = .clear
        view.layer.borderWidth = 0
        view.layer.borderColor = .none
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        view.backgroundColor = .lightGray
    }
    
    
    func setupConstraints(){
        contentView.addSubview(view);
        
        view.snp.makeConstraints{make in
            make.trailing.equalToSuperview().inset(20);
            make.leading.equalToSuperview().offset(20);
            make.top.equalToSuperview().offset(10);
            make.bottom.equalToSuperview().inset(10)
        }

    }

    override func prepareForReuse() {
           super.prepareForReuse()
           // ✅ 기존 뷰를 유지하여 성능 최적화
    }
    
}
