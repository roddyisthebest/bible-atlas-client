//
//  DiffTableViewCell.swift
//  BibleAtlas
//
//  Created by 배성연 on 3/3/25.
//

import UIKit

class DiffTableViewCell: UITableViewCell {
    
    static let identifier = "diffCell"

    
    private lazy var container = {
        let v = UIView();
        addSubview(v)
    
        v.addSubview(lineContainer)
        v.addSubview(contentContainer)
        return v;
    }()
    
    private lazy var lineContainer =  {
        let sv = UIStackView(arrangedSubviews: [oldLineLabel, newLineLabel]);
        sv.axis = .horizontal;
        sv.distribution = .fillEqually;
        sv.alignment = .center
        
        return sv;
    }()
    
    private let oldLineLabel = {
        let label = UILabel();
        label.font = .boldSystemFont(ofSize: 12);
        label.textColor = .diffLabel
        label.textAlignment = .center;
        return label;
    }()
    
    private let newLineLabel = {
        let label = UILabel();
        label.font = .boldSystemFont(ofSize: 12);
        label.textColor = .diffLabel
        label.textAlignment = .center;

        return label;
    }()
    
    
    private lazy var contentContainer = {
        let v = UIView();
        v.addSubview(contentStackView)
        return v;
    }()
    
    private lazy var contentStackView = {
        let sv = UIStackView(arrangedSubviews: [contentMarkImage, contentTextView]);
        sv.axis = .horizontal;
        sv.distribution = .fill;
        sv.alignment = .center;
        sv.spacing = 10;
        
        return sv;
    }()
        
    private let contentMarkImage = {
        let iv = UIImageView();
        iv.tintColor = .black
        iv.contentMode = .scaleAspectFit

        return iv;
    }()
        

    private let contentTextView = {
        let tv = UITextView();
        tv.textColor = .black;
        tv.font = .systemFont(ofSize: 12)
        tv.isScrollEnabled = false;
        tv.isEditable = false;
        
        tv.setContentHuggingPriority(.required, for: .vertical)
        tv.textAlignment = .left
        tv.backgroundColor = .clear
        
        return tv;
    }()
    
    var diffCode:DiffCode?{
        didSet {
            guard let diffCode = diffCode else { return }
                   if oldValue != diffCode {  // ✅ 값이 변경된 경우만 업데이트
                       updateUI(with:diffCode)
                   }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupConstraint();
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    
    func configure(diffCode:DiffCode){
        self.diffCode = diffCode
    }
    
    private func updateUI(with diffCode:DiffCode){
        oldLineLabel.text = diffCode.oldLineNumber == -1 ?  "" : String(diffCode.oldLineNumber);
        newLineLabel.text = diffCode.newLineNumber == -1 ?  "" : String(diffCode.newLineNumber);
            
        contentTextView.text = diffCode.content;
        
        
        
        
        switch(diffCode.status){
            case .add:
                lineContainer.backgroundColor = .diffLightGreen;
                contentContainer.backgroundColor = .diffGreen;
                newLineLabel.textColor = .black;
                contentMarkImage.image = UIImage(systemName: "plus")
                lineContainer.alignment = .bottom
            case .delete:
                lineContainer.backgroundColor = .diffLightRed;
                contentContainer.backgroundColor = .diffRed;
                oldLineLabel.textColor = .black;
                contentMarkImage.image = UIImage(systemName: "minus")
                lineContainer.alignment = .top

            case .notChange:
                lineContainer.backgroundColor = .diffLightGray;
                contentContainer.backgroundColor = .white;
        }
        
    }
    
    
    private func setupConstraint(){
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview();
        }
        
        lineContainer.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview();
            make.width.equalToSuperview().multipliedBy(0.3);

        }
        
        contentContainer.snp.makeConstraints { make in
            make.top.trailing.bottom.equalToSuperview();
            make.leading.equalTo(lineContainer.snp.trailing);
        }
        
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview();
        }
        
        contentMarkImage.snp.makeConstraints { make in
            make.height.width.equalTo(25)
        }
        
    }
}
