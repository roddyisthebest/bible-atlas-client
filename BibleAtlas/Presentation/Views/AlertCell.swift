//
//  AlertCell.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/11/25.
//

import UIKit
import SnapKit

class AlertCell: UITableViewCell {

    static let identifier = "AlertCell"
    
    
    let wrapperView = {
        let view = UIView();
        view.backgroundColor = .lightGray;
        view.layer.borderWidth = 0
        view.layer.borderColor = .none
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view;
    }();
    
    
    let stackView:UIStackView = {
        let st = UIStackView();
        st.axis = .horizontal;
        st.alignment = .center;
        st.spacing = 10;
        st.backgroundColor = .clear
        return st;
    }()
    
    
    
    
    let alertImageWrapperView = {
        let view = UIView();
        view.layer.cornerRadius = 25;
        view.clipsToBounds = true;
        return view;
    }();
    
    
    let alertImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
        imageView.image = UIImage(systemName: "bell.fill")
        return imageView
    }();
    
    let contentStackView = {
        let st = UIStackView();
        st.axis = .vertical;
        st.alignment = .leading;
        st.spacing = 5;
        return st;
    }();
    
    let titleStackView = {
        let st = UIStackView();
        st.axis = .horizontal;
        st.alignment = .firstBaseline
        st.distribution = .fill
        st.spacing = 10
        return st;
    }();
    
    var titleLabel = {
        let label = UILabel();
        label.font = .systemFont(ofSize: 16, weight: .bold);
        label.lineBreakMode = .byTruncatingTail;
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        label.text = "달리치안스코리아마나ㅏ"
        label.textColor = .white
        return label;
    }();
    
    let timeLabel = {
        let label = UILabel();
        label.font = .systemFont(ofSize: 16)
        label.textColor = .white
        label.setContentHuggingPriority(.required, for: .horizontal) // 최대한 오른쪽 배치
        label.setContentCompressionResistancePriority(.required, for: .horizontal)

        label.text = "10분전"
        return label;
    }();
    
    let contentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail;
        label.textColor = .white
        label.text = "aflsdf;asㅁㄴㅇㅁㄴㅇㅁㄴㅇㅁㄴㅇㅁㄴㅇㅁㄴㅇㅁㄴㅇㅁㄴㅇㅁㄴㅇㄴㅇㄴㅇㄴ"
        return label
    }()
    

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI();
        setupStyle();
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
        
    
    
    private func setupStyle(){
        contentView.backgroundColor = .clear
    }

    private func setupConstraints(){
        wrapperView.snp.makeConstraints{ make in
            make.leading.top.equalToSuperview().offset(10);
            make.trailing.bottom.equalToSuperview().inset(10);
            
        }
        
//        stackView.snp.makeConstraints{ make in
//            make.leading.top.equalToSuperview().offset(10);
//            make.trailing.bottom.equalToSuperview().inset(10)
//        }
//        
//        alertImageWrapperView.snp.makeConstraints{make in
//            make.width.equalTo(50)
//            make.height.equalTo(50)
//
//        }
//        
//        alertImageView.snp.makeConstraints{make in
//            make.width.equalTo(30);
//            make.height.equalTo(30);
//            make.trailing.bottom.equalToSuperview().inset(10);
//        }
//        
// 
//        
//        
//        contentStackView.snp.makeConstraints{make in
//            make.trailing.equalToSuperview().inset(10)
//        }
//        
//        titleStackView.snp.makeConstraints{make in
//            make.width.equalToSuperview()
//        }
        
    }
    
    private func setupUI(){
        contentView.addSubview(wrapperView);
//        wrapperView.addSubview(stackView);
//        stackView.addArrangedSubview(alertImageWrapperView)
//        alertImageWrapperView.addSubview(alertImageView);
//        stackView.addArrangedSubview(contentStackView);
//        contentStackView.addArrangedSubview(titleStackView);
//        contentStackView.addArrangedSubview(contentLabel)
//        titleStackView.addArrangedSubview(titleLabel);
//        titleStackView.addArrangedSubview(timeLabel);
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
