//
//  LoginViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/4/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class LoginViewController: UIViewController {

    weak var appCoordinator: AppCoordinatorProtocol?
    
    let loginViewModel: LoginViewModelProtocol;
    
    let disposeBag = DisposeBag();
    
    let bibleImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named:"bibleImage"));
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        return imageView;
    }()
    
    
    let userIdField: UITextField = {
        let textField = UITextField()
        textField.backgroundColor = UIColor.primaryInput
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no

        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textField.leftViewMode = .always

        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textField.rightViewMode = .always
        textField.textColor = .white
        textField.autocapitalizationType = .none

        textField.attributedPlaceholder = NSAttributedString(
            string: "아이디를 입력해주세요.",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        );
        return textField
    }()
    
    let passwordField: UITextField = {
        let textField = UITextField();
        textField.backgroundColor = UIColor.primaryInput;
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        
        
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textField.leftViewMode = .always

        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textField.rightViewMode = .always
        textField.textColor = .white

        textField.autocapitalizationType = .none
        textField.attributedPlaceholder = NSAttributedString(
            string: "비밀번호를 입력해주세요.",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        )
        return textField;
    }()
    
    
    let loginButton:UIButton = {
        let button = UIButton();
        button.backgroundColor = UIColor.primaryViolet;
        button.setTitleColor(.white, for:.normal);
        button.setTitle("로그인", for: .normal)
        return button;
    }()
    
    let fieldStackView:UIStackView = {
        let st = UIStackView();
        st.axis = .vertical;
        st.alignment = .fill;
        st.distribution = .fillEqually;
        st.spacing = 10.0;

        return st;
    }();
    
    init(loginViewModel: LoginViewModelProtocol, appCoordinator:AppCoordinatorProtocol) {
        self.loginViewModel = loginViewModel;
        self.appCoordinator = appCoordinator;
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI();
        setConstraint();
        bindViewModel();
    }
    
    private func setUI(){
        view.backgroundColor = .backgroundDark
        
        view.addSubview(bibleImageView);
        view.addSubview(fieldStackView);
        
        fieldStackView.addArrangedSubview(userIdField);
        fieldStackView.addArrangedSubview(passwordField);
        fieldStackView.addArrangedSubview(loginButton);

    }
    
    private func setConstraint(){
        bibleImageView.snp.makeConstraints{make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(30);
            make.trailing.leading.equalToSuperview().offset(20);
            make.height.equalTo(200)
        }
        
        fieldStackView.snp.makeConstraints{make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(30)
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);

        }
        
        userIdField.snp.makeConstraints{make in
            make.height.equalTo(50);
        }
        
        passwordField.snp.makeConstraints{make in
            make.height.equalTo(50);
        }
        
        loginButton.snp.makeConstraints{make in make.height.equalTo(50)}
        
    }
    
    private func bindViewModel(){
        
        let userId$ = userIdField.rx.text.orEmpty.asObservable();
        let password$ = passwordField.rx.text.orEmpty.asObservable();
        
        let buttonTapped$ = loginButton.rx.tap.asObservable();
        
        
        
        let output = loginViewModel.transform(input: LoginViewModel.Input(userId$: userId$, password$: password$, buttonTapped$: buttonTapped$))
            
        output.loginResponse$.observe(on: MainScheduler.instance).bind{
            [weak self] response in
            print(response,"response")
            self?.navigateToMainTab();
        }.disposed(by: disposeBag)
        
        output.error$.observe(on: MainScheduler.instance).bind{
            [weak self] errorMsg in
            let alert = UIAlertController(title: "에러", message: errorMsg, preferredStyle: .alert);
            alert.addAction(.init(title:"확인", style:.default));
            self?.present(alert,animated: true);

        }.disposed(by: disposeBag)
        
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

    
    private func navigateToMainTab() {
        appCoordinator?.showMainTabFlow();
    }



}


extension UIColor {
    
    convenience init(hex: String) {
           var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
           hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

           var rgb: UInt64 = 0
           Scanner(string: hexSanitized).scanHexInt64(&rgb)

           let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
           let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
           let b = CGFloat(rgb & 0xFF) / 255.0

           self.init(red: r, green: g, blue: b, alpha: 1.0)
       }
    
    
    static let backgroundDark = UIColor(hex: "#1E1E1E")  // 배경색
    static let primaryBlue = UIColor(hex: "#007AFF")  // iOS 기본 파란색
    static let secondaryGray = UIColor(hex: "#8E8E93")  // 시스템 그레이
    static let primaryInput = UIColor(hex: "#313131")
    static let primaryViolet = UIColor(hex: "#8160C4")
    
    
    static let primaryRed = UIColor(hex:"#FF7979");
    static let thirdGray = UIColor(hex:"#313131")
    
    static let lightGray = UIColor(hex:"#5D5D5D")
    static let lightestGray = UIColor(hex:"#DBDBDB")
    static let tabbarGray = UIColor(hex:"#404040")
    static let wrapperGray = UIColor(hex:"#5D5D5D")
    
    static let activityCreationBGColor = UIColor(hex:"#E2F3FF")
    static let activityCreationTextColor = UIColor(hex:"#57B9FF")

    static let activityUpdateBGColor = UIColor(hex:"#E9FFE2")
    static let activityUpdateTextColor = UIColor(hex:"#4ABD26")
    
    static let activityDeleteBGColor = UIColor(hex:"#FFEAEA")
    static let activityDeleteTextColor = UIColor(hex:"#FF1D1D")
    
    static let upIconColor = UIColor(hex:"#47FF78");
    static let downIconColor = UIColor(hex:"#FF5454");

    
    static let diffLightGreen = UIColor(hex:"#F0FFF1");
    static let diffGreen = UIColor(hex:"#CEFFD2");
    
    static let diffLightRed = UIColor(hex:"#FFE6E6");
    static let diffRed = UIColor(hex:"#FFCECE")
    
    static let diffLightGray = UIColor(hex:"#F2F2F2")
    
    static let diffLabel = UIColor(hex:"#767676")
    
}
