//
//  LoginBottomSheetViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/26/25.
//

import UIKit

class LoginBottomSheetViewController: UIViewController {
    
    private lazy var headerStackView = {
        let sv = UIStackView(arrangedSubviews: [headerLabel, closeButton]);
        sv.axis = .horizontal;
        sv.distribution = .fillProportionally;
        sv.alignment = .center
        return sv;
    }()
    
    
    private let headerLabel = HeaderLabel(text: "Login");
    private let closeButton = CloseButton();
    
    
    private lazy var buttonsStackView = {
        let sv = UIStackView(arrangedSubviews: [googleButton, kakaoButton]);
        sv.axis = .vertical;
        sv.distribution = .fill;
        sv.alignment = .fill
        sv.spacing = 10;
        return sv;
    }()
        
    private let googleButton = GuideButton(titleText: "Google");
    private let kakaoButton = GuideButton(titleText: "Kakao");

    private func setupStyle(){
        view.backgroundColor = .mainBkg;
    }
    
    private func setupUI(){
        view.addSubview(headerStackView)
        view.addSubview(buttonsStackView)
    }
    
    private func setupConstraints(){
        headerStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);

        }
        
        buttonsStackView.snp.makeConstraints { make in
            make.top.equalTo(headerStackView.snp.bottom).offset(20);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI();
        setupConstraints();
        setupStyle()

    }
    
}
