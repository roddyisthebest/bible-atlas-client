//
//  LoginBottomSheetViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/26/25.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseCore
import GoogleSignIn

final class LoginBottomSheetViewController: UIViewController {
    
    private var loginBottomSheetViewModel:LoginBottomSheetViewModelProtocol?;
    
    private var disposeBag = DisposeBag();
    
    private lazy var headerStackView = {
        let sv = UIStackView(arrangedSubviews: [headerLabel, closeButton]);
        sv.axis = .horizontal;
        sv.distribution = .fillProportionally;
        sv.alignment = .center
        return sv;
    }()
    
    
    private let headerLabel = HeaderLabel(text: "Login");
    private let closeButton = CircleButton(iconSystemName: "xmark" );
    
    private let googleLoginSuccessed$ = BehaviorRelay<String?>(value: nil);
    
    private lazy var buttonsStackView = {
        let sv = UIStackView(arrangedSubviews: [localButton, googleButton, kakaoButton]);
        sv.axis = .vertical;
        sv.distribution = .fill;
        sv.alignment = .fill
        sv.spacing = 10;
        return sv;
    }()
    
    private let localButton = GuideButton(titleText: "Local");
    private let googleButton = {
        let button = GuideButton(titleText: "Google");
        button.addTarget(self, action: #selector(googleLoginButtontapped), for: .touchUpInside)
        return button;
    }()
    private let kakaoButton = GuideButton(titleText: "Kakao");
    
    
    init(loginBottomSheetViewModel:LoginBottomSheetViewModelProtocol) {
        self.loginBottomSheetViewModel = loginBottomSheetViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        print("🔥 LoginBottomSheetVC deinit")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bindViewModel(){
        let kakaoButtonTapped$ = kakaoButton.rx.tap.asObservable();
        let closeButtonTapped$ = closeButton.rx.tap.asObservable();
        let localButtonTapped$ = localButton.rx.tap.asObservable();
        
        let output = loginBottomSheetViewModel?.transform(input: LoginBottomSheetViewModel.Input(localButtonTapped$: localButtonTapped$.asObservable(), googleLoginSuccessed$: googleLoginSuccessed$.asObservable(), kakaoButtonTapped$: kakaoButtonTapped$, closeButtonTapped$:closeButtonTapped$))
        
        output?.error$.subscribe(onNext: { [weak self] error in
            switch(error){
                case .serverErrorWithMessage(let errorResponse):
                    self?.showAlert(message: errorResponse.message)
                default:
                    self?.showAlert(message: error.description)
                }
        }).disposed(by: disposeBag)
        
        
        output?.localLoading$.subscribe(onNext: { [weak self] loading in
            DispatchQueue.main.async {
                self?.localButton.setLoading(loading)
            }
        }).disposed(by: disposeBag)
        
        output?.googleLoading$.subscribe(onNext:{ [weak self] loading in
            DispatchQueue.main.async{
                self?.googleButton.setLoading(loading)
            }
        }).disposed(by: disposeBag)
    }
    
    @objc private func googleLoginButtontapped(){
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: self){ [weak self] result, error in
            guard let idToken = result?.user.idToken else { return }
            self?.googleLoginSuccessed$.accept(idToken.tokenString)
        }
        
        
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
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        DispatchQueue.main.async {
            self.present(alert, animated: true)
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
