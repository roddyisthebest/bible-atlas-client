//
//  TableViewCell.swift
//  BibleAtlas
//
//  Created by 배성연 on 7/24/25.
//

import UIKit

final class ReportTypeTableViewCell: UITableViewCell {
    
    static let identifier = "reportTypeCell"

    private lazy var stackView = {
        let sv = UIStackView(arrangedSubviews: [label, checkIcon])
        sv.axis = .horizontal;
        sv.distribution = .fillProportionally;
        sv.alignment = .center;
    
        return sv
    }()
    
    private let label = {
        let label = UILabel();
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .mainText
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private let checkIcon:UIImageView = {
        let icon = UIImageView(image: UIImage(systemName: "checkmark"))
        icon.tintColor = .primaryBlue
        icon.contentMode = .right
        return icon
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()

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

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func setReportType(report: PlaceReportType, isCheck:Bool) {
        var text = ""
        switch report {
        case .spam:
            text = "스팸"
        case .inappropriate:
            text = "부적절한 내용"
        case .hateSpeech:
            text = "혐오 발언"
        case .falseInfomation:
            text = "거짓 정보"
        case .personalInfomation:
            text = "개인적인 정보"
        case .etc:
            text = "기타"
        }

        label.text = text;
        checkIcon.isHidden = !isCheck
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
