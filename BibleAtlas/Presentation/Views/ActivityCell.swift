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
    
    private lazy var titleStackView = {
        let sv = UIStackView(arrangedSubviews: [statusView,titleContentStackView]);
        sv.axis = .horizontal;
        sv.spacing = 12;
        sv.alignment = .center
        
        view.addSubview(sv)
        return sv;
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel();
        label.numberOfLines = 4;
        label.lineBreakMode = .byTruncatingTail;
        label.text = "여기ㅇㅁㄴㅇㄴㅇㄴㅇㄴㅇㄴㅇㅁㄴㅇ여기ㅇㅁㄴㅇㄴㅇㄴㅇㄴㅇㄴㅇㅁㄴㅇ여기ㅇㅁㄴㅇㄴㅇㄴㅇㄴㅇㄴㅇㅁㄴㅇ여기ㅇㅁㄴㅇㄴㅇㄴㅇㄴㅇㄴㅇㅁㄴㅇ여기ㅇㅁㄴㅇㄴㅇㄴㅇㄴㅇㄴㅇㅁㄴㅇ여기ㅇㅁㄴㅇㄴㅇㄴㅇㄴㅇㄴㅇㅁㄴㅇ asdasdsdasdasdsdsdasd";
        label.textColor = .white;
        label.font = UIFont.systemFont(ofSize: 14);
        label.textAlignment = .left
        view.addSubview(label)

        return label;
    }()
    
    private lazy var statusView = {
        let v = UIView();
        v.layer.cornerRadius = 25;
        v.layer.masksToBounds = true;
        v.addSubview(statusLabel)
        return v;
    }()
    
    private let statusLabel = {
        let label = UILabel();
        label.font = UIFont.boldSystemFont(ofSize: 20);
        label.text = "생성"
        return label;
    }()
    
    private lazy var titleContentStackView = {
        let sv = UIStackView(arrangedSubviews: [titleLabel, subContentStackView])
        sv.axis = .vertical
        sv.spacing = 4
        sv.alignment = .leading
        
        return sv
    }()
    
    private let titleLabel = {
        let label = UILabel();
        label.font = UIFont.boldSystemFont(ofSize: 16);
        label.textColor = .white;
        label.text = "달리치안소 달리치안소"
        return label;
    }()
    
    private lazy var subContentStackView = {
        let sv = UIStackView(arrangedSubviews: [timeLabel, voteResultWrapperStackView]);
        sv.axis = .horizontal;
        sv.spacing = 12;
        sv.alignment = .center
        
        return sv;
    }()
    
    private let timeLabel = {
        let label = UILabel();
        label.text = "10분전"
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = .white
        return label;
    }()
    
    
    private lazy var voteResultWrapperStackView = {
        let sv = UIStackView(arrangedSubviews: [voteUpResultStackView, voteDownResultStackView, userStackView]);
        sv.axis = .horizontal;
        sv.spacing = 6;
        sv.alignment = .center
        
        return sv;
    }();
    
    
    private lazy var voteUpResultStackView = {
        let sv = UIStackView(arrangedSubviews: [voteUpResultIcon, voteUpResultLabel]);
        sv.axis = .horizontal;
        sv.spacing = 3;
        sv.alignment = .center
        return sv;
    }()
    
    private let voteUpResultIcon = {
        let image = UIImage(systemName: "arrow.up")
        let icon = UIImageView(image:image)
        return icon;
    }()
    
    private let voteUpResultLabel = {
        let label = UILabel();
        label.text = "10"
        label.textColor = .white;
        label.font = UIFont.systemFont(ofSize: 13)
        return label
    }()
    
    

    
    private lazy var voteDownResultStackView = {
        let sv = UIStackView(arrangedSubviews: [voteDownResultIcon, voteDownResultLabel]);
        sv.axis = .horizontal;
        sv.spacing = 3;
        sv.alignment = .center
        
        return sv;
    }()
    
    
    private let voteDownResultIcon = {
        let image = UIImage(systemName: "arrow.down")
        let icon = UIImageView(image:image)
        return icon;
    }()
    
    private let voteDownResultLabel = {
        let label = UILabel();
        label.text = "10"
        label.textColor = .white;
        label.font = UIFont.systemFont(ofSize: 13)
        return label
    }()
    
    
    private lazy var userStackView = {
        let sv = UIStackView(arrangedSubviews: [userImageView, userLabel]);
        sv.axis = .horizontal;
        sv.spacing = 6;
        sv.alignment = .center
        
        return sv;
    }()
    
    private let userImageView = {
        let image = UIImage(systemName: "person.circle")
        let iv = UIImageView(image:image)
        return iv;
    }()
    
    private let userLabel = {
        let label = UILabel();
        label.text = "shy"
        label.textColor = .white;
        label.font = UIFont.systemFont(ofSize: 13)
        return label
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
    
    private func setupStyle(){
        contentView.backgroundColor = .clear
        view.layer.borderWidth = 0
        view.layer.borderColor = .none
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        view.backgroundColor = .lightGray
    }
    
    
    private func setupConstraints(){
        contentView.addSubview(view);

        view.snp.makeConstraints{make in
            make.trailing.equalToSuperview().inset(20);
            make.leading.equalToSuperview().offset(20);
            make.top.equalToSuperview().offset(10);
            make.bottom.equalToSuperview().inset(10)
        }
        
        titleStackView.snp.makeConstraints{make in
            make.top.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);

            make.height.equalTo(50)
        }
        
        descriptionLabel.snp.makeConstraints{make in
            
            make.trailing.equalToSuperview().inset(20);
            make.leading.equalToSuperview().offset(20);
            make.top.equalTo(titleStackView.snp.bottom).offset(20);
            make.bottom.equalToSuperview().inset(20)
        }
        
        
        statusView.snp.makeConstraints{make in
            make.width.height.equalTo(50);
        }
        
        statusLabel.snp.makeConstraints{make in
            make.center.equalToSuperview();
        }
        
        voteUpResultIcon.snp.makeConstraints{make in
            make.width.equalTo(15)
            make.height.equalTo(17.5)
        }
        
        voteDownResultIcon.snp.makeConstraints{make in
            make.width.equalTo(15)
            make.height.equalTo(17.5)
        }

    }
    
    func configure(text:String?){
        descriptionLabel.text = text;
    }

    override func prepareForReuse() {
           super.prepareForReuse()
           // ✅ 기존 뷰를 유지하여 성능 최적화
    }
    
}
