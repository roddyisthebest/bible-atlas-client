//
//  LocationComfirmBottomSheet.swift
//  BibleAtlas
//
//  Created by 배성연 on 3/9/25.
//

import UIKit

class LocationComfirmBottomSheet: UIViewController {
    
    
    private lazy var container = {
        let v = UIView();
        v.backgroundColor = .thirdGray;
        view.addSubview(v)
        v.addSubview(titleView)
        v.addSubview(buttonWrapper)
        return v;
    }();
    
    
    private lazy var titleView = {
        let v = UIView();
        v.addSubview(titleLabel);
        v.addSubview(descLabel);
        return v;
    }();
    
    private let titleLabel = {
        let label = UILabel();
        label.text = "double by hillton"
        label.font = UIFont.systemFont(ofSize: 20, weight: .heavy)
        label.textColor = .white;
        label.lineBreakMode = .byTruncatingTail;
        return label;
    }();
    
    
    private let descLabel = {
        let label = UILabel();
        label.text = "double by hillton"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .white;
        label.lineBreakMode = .byTruncatingTail;
        return label;
    }();
    
    
    private lazy var buttonWrapper = {
        let v = UIView();
        v.addSubview(buttonsContainer)
        return v;
    }();
    
    private lazy var buttonsContainer = {
        let sv = UIStackView(arrangedSubviews: [selectButton, cancelButton]);

        sv.axis = .vertical;
        sv.distribution = .fill;
        sv.alignment = .fill;
        sv.spacing = 10;
        
        return sv;
    }();
    
    
    private lazy var selectButton = {
        let button = UIButton()
        button.backgroundColor = .primaryViolet;
        button.layer.cornerRadius = 25
        button.addSubview(selectIcon)
        button.addSubview(selectButtonLabel)
        return button;
    }();
    
    private let selectIcon = {
        let image = UIImage(systemName: "hand.tap.fill");
        let iv = UIImageView(image:image);
        iv.contentMode = .scaleAspectFit;
        iv.tintColor = .white;
        return iv;
    }();
    
    private let selectButtonLabel = {
        let label = UILabel();
        label.text = "선택하기"
        label.textColor = .white;
        label.font = .systemFont(ofSize: 20, weight: .heavy);
        return label;
    }();
    
    
    private lazy var cancelButton = {
        let button = UIButton()
        button.backgroundColor = .primaryRed;
        button.layer.cornerRadius = 25
        button.addSubview(cancelIcon)
        button.addSubview(cancelButtonLabel)
        button.addTarget(self, action: #selector(closeBottomSheet), for: .touchUpInside)
        return button;
    }();
    
    private let cancelIcon = {
        let image = UIImage(systemName: "xmark");
        let iv = UIImageView(image:image);
        iv.contentMode = .scaleAspectFit;
        iv.tintColor = .white;
        return iv;
    }();
    
    private let cancelButtonLabel = {
        let label = UILabel();
        label.text = "취소하기"
        label.textColor = .white;
        label.font = .systemFont(ofSize: 20, weight: .heavy);
        return label;
    }();
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupStyle()
        setupConstraints()
    }
    
    
    private func setupStyle(){
        view.backgroundColor = .clear
    }
    
    @objc private func closeBottomSheet(){
        dismiss(animated: true)
    }
    
    private func setupConstraints(){
        
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview();
        }
        
        titleView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
        }
        
        
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        
        descLabel.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalToSuperview();
            make.top.equalTo(titleLabel.snp.bottom);
        }
        
        buttonWrapper.snp.makeConstraints { make in
            make.top.equalTo(titleView.snp.bottom)
            make.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
        }
        
        
        buttonsContainer.snp.makeConstraints { make in
            make.leading.trailing.centerY.equalToSuperview();
        }
        
        cancelButton.snp.makeConstraints { make in
            make.height.equalTo(60)
        }
        
        cancelIcon.snp.makeConstraints { make in
            make.width.height.equalTo(30);
            make.centerY.equalToSuperview();
            make.trailing.equalToSuperview().inset(20);
        }
        
        cancelButtonLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview();
            make.leading.equalToSuperview().offset(20);
        }
        
        selectButton.snp.makeConstraints { make in
            make.height.equalTo(60)
        }
        
        selectIcon.snp.makeConstraints { make in
            make.width.height.equalTo(30);
            make.centerY.equalToSuperview();
            make.trailing.equalToSuperview().inset(20);
        }
        
        selectButtonLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview();
            make.leading.equalToSuperview().offset(20);
        }
        
    }
}
