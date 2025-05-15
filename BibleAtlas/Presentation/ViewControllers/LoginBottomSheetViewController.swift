//
//  LoginBottomSheetViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/26/25.
//

import UIKit
import RxSwift
import RxCocoa
import PanModal
final class LoginBottomSheetViewController: UIViewController, PanModalPresentable {
    var shouldShowBackgroundView: Bool {
        return true;
    }
    
    var panScrollable: UIScrollView? {
        return nil
    }
    
    private var loginBottomSheetViewModel:LoginBottomSheetViewModelProtocol?;
    
    private lazy var headerStackView = {
        let sv = UIStackView(arrangedSubviews: [headerLabel, closeButton]);
        sv.axis = .horizontal;
        sv.distribution = .fillProportionally;
        sv.alignment = .center
        return sv;
    }()
    
    
    private let headerLabel = HeaderLabel(text: "Login");
    private let closeButton = CircleButton(iconSystemName: "xmark" );
    
    
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

        
    init(loginBottomSheetViewModel:LoginBottomSheetViewModelProtocol) {
        self.loginBottomSheetViewModel = loginBottomSheetViewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bindViewModel(){
        let googleButtonTapped$ = googleButton.rx.tap.asObservable();
        let kakaoButtonTapped$ = kakaoButton.rx.tap.asObservable();
        let closeButtonTapped$ = closeButton.rx.tap.asObservable();
        
        loginBottomSheetViewModel?.transform(input: LoginBottomSheetViewModel.Input(googleButtonTapped$: googleButtonTapped$, kakaoButtonTapped$: kakaoButtonTapped$, closeButtonTapped$:closeButtonTapped$))
    }
    
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
        bindViewModel();
    }
    
}
