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
import AuthenticationServices
import SnapKit

final class LoginBottomSheetViewController: UIViewController {
    
    private var loginBottomSheetViewModel:LoginBottomSheetViewModelProtocol?;
    
    private var disposeBag = DisposeBag();
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    
    
    private var localLoginBottomConstraint: Constraint?

    private lazy var headerStackView = {
        let sv = UIStackView(arrangedSubviews: [headerLabel, closeButton]);
        sv.axis = .horizontal;
        sv.distribution = .fillProportionally;
        sv.alignment = .center
        return sv;
    }()
    
    
    private let headerLabel = HeaderLabel(text: L10n.Auth.title);
    private let closeButton = CircleButton(iconSystemName: "xmark" );
    
    private let googleTokenReceived$ = BehaviorRelay<String?>(value: nil);
    private let appleTokenReceived$ = BehaviorRelay<String?>(value: nil);
    
    
    private let localLoginTapped$ = BehaviorRelay<(String?,String?)>(value: (nil, nil))

    private lazy var buttonsStackView = {
        let sv = UIStackView(arrangedSubviews: [googleButton, appleButton]);
        sv.axis = .vertical;
        sv.distribution = .fill;
        sv.alignment = .fill
        sv.spacing = 10;
        return sv;
    }()
    

    private let googleButton = {
        let button = GuideButton(titleText: L10n.Auth.continueWithGoogle);
        button.addTarget(self, action: #selector(googleLoginButtonTapped), for: .touchUpInside)
        return button;
    }()
    private let appleButton = {
        let button = GuideButton(titleText: L10n.Auth.continueWithApple);
        button.addTarget(self, action: #selector(appleLoginButtonTapped), for: .touchUpInside)
        return button;
    }()


    
    
    private lazy var dividerView: UIView = {
        let container = UIView()

        let leftLine = UIView()
        leftLine.backgroundColor = .dividerBkg

        let rightLine = UIView()
        rightLine.backgroundColor = .dividerBkg

        let label = UILabel()
        label.text = "OR"
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .mainText
        label.textAlignment = .center
        label.backgroundColor = .mainBkg

        let stackView = UIStackView(arrangedSubviews: [leftLine, label, rightLine])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.distribution = .fill   // 이거 그대로 둬도 됨

        container.addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 라인 뷰는 얇은 선처럼 (height만 주고)
        leftLine.snp.makeConstraints { make in
            make.height.equalTo(1)
        }

        rightLine.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.width.equalTo(leftLine.snp.width) // ⬅️ 이 한 줄 추가!!
        }

        return container
    }()
    
    
    private let idTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email or ID"
        tf.font = .systemFont(ofSize: 14, weight: .regular)
        tf.textColor = .mainText
        tf.backgroundColor = .mainItemBkg
        tf.layer.cornerRadius = 8
        tf.layer.masksToBounds = true
        tf.autocapitalizationType = .none
        tf.keyboardType = .emailAddress
        tf.returnKeyType = .next
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        tf.leftViewMode = .always

        // 🔥 높이 고정
        tf.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        
        tf.accessibilityIdentifier = "login_id_textfield"


        return tf
    }()


    private let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.font = .systemFont(ofSize: 14, weight: .regular)
        tf.textColor = .mainText
        tf.backgroundColor = .mainItemBkg
        tf.layer.cornerRadius = 8
        tf.layer.masksToBounds = true
        tf.isSecureTextEntry = true
        tf.autocapitalizationType = .none
        tf.returnKeyType = .done
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        tf.leftViewMode = .always
        tf.snp.makeConstraints { make in
            make.height.equalTo(44)
        }

        tf.accessibilityIdentifier = "login_password_textfield"

        return tf
    }()

    private let localLoginButton: GuideButton = {
        let button = GuideButton(titleText: L10n.Auth.title)

        button.addTarget(self, action: #selector(emitLocalLogin), for: .touchUpInside)
        button.accessibilityIdentifier = "login_local_button"

        return button
    }()

    private lazy var localLoginStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [idTextField, passwordTextField, localLoginButton])
        sv.axis = .vertical
        sv.alignment = .fill
        sv.distribution = .fill
        sv.spacing = 10
        return sv
    }()


    
    
    init(loginBottomSheetViewModel:LoginBottomSheetViewModelProtocol) {
        self.loginBottomSheetViewModel = loginBottomSheetViewModel
        super.init(nibName: nil, bundle: nil)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("🔥 LoginBottomSheetVC deinit")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bindViewModel(){

        let closeButtonTapped$ = closeButton.rx.tap.asObservable();

        
        
        let output = loginBottomSheetViewModel?.transform(input: LoginBottomSheetViewModel.Input(googleTokenReceived$: googleTokenReceived$.asObservable(), appleTokenReceived$: appleTokenReceived$.asObservable(), localLoginButtonTapped$: localLoginTapped$.asObservable(), closeButtonTapped$: closeButtonTapped$))
        
        
        output?.error$.subscribe(onNext: { [weak self] error in
            switch(error){
                case .serverErrorWithMessage(let errorResponse):
                    self?.showAlert(message: errorResponse.message)
                default:
                    self?.showAlert(message: error.description)
                }
        }).disposed(by: disposeBag)
        
        output?.googleLoading$.subscribe(onNext:{ [weak self] loading in
            DispatchQueue.main.async{
                self?.googleButton.setLoading(loading)
            }
        }).disposed(by: disposeBag)
        
        output?.appleLoading$.subscribe(onNext:{ [weak self] loading in
            DispatchQueue.main.async{
                self?.appleButton.setLoading(loading)
            }
        }).disposed(by: disposeBag)
        
        output?.localLoading$.subscribe(onNext:{[weak self] loading in
            DispatchQueue.main.async{
                self?.localLoginButton.setLoading(loading)
            }
        }).disposed(by: disposeBag)
        
        
        
    }
    
    @objc private func googleLoginButtonTapped(){
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: self){ [weak self] result, error in
        
            if(error != nil){
                guard let error = error else {return}
                self?.showAlert(message: error.localizedDescription)
                return;
            }
            
            guard let idToken = result?.user.idToken else { return }
            self?.googleTokenReceived$.accept(idToken.tokenString)
        }
    }
    
    
    @objc private func appleLoginButtonTapped(){
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
        
    }
    
    
    private func setupStyle(){
        view.backgroundColor = .mainBkg;
    }
    
    private func setupUI(){
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(headerStackView)
        contentView.addSubview(buttonsStackView)
        contentView.addSubview(dividerView)
        contentView.addSubview(localLoginStackView)

    }
    
    private func setupConstraints() {
        // scrollView를 전체 화면에 붙이기
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        // contentView를 scrollView 안에 꽉 채우기
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide) // 가로 스크롤 막기
        }

        // 여기부터는 "예전에 view 기준으로 잡던 걸 contentView 기준으로"만 바꾸면 됨

        headerStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }

        buttonsStackView.snp.makeConstraints { make in
            make.top.equalTo(headerStackView.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }

        dividerView.snp.makeConstraints { make in
            make.top.equalTo(buttonsStackView.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(20)
        }

        localLoginStackView.snp.makeConstraints { make in
            make.top.equalTo(dividerView.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-20) // 🔥 contentView의 bottom!
        }
    }

    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: L10n.Common.errorTitle, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.Common.ok, style: .default))
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
    
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func handleKeyboardWillShow(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }
        
        let keyboardFrameInView = view.convert(keyboardFrame, from: nil)
        let overlap = max(0, view.bounds.maxY - keyboardFrameInView.origin.y)
        
        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)
        
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
            self.scrollView.contentInset.bottom = overlap
            self.scrollView.scrollIndicatorInsets.bottom = overlap
        }, completion: nil)
    }

    @objc private func handleKeyboardWillHide(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }
        
        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)
        
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
            self.scrollView.contentInset.bottom = 0
            self.scrollView.scrollIndicatorInsets.bottom = 0
        }, completion: nil)
    }

    private func delegate(){
        idTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    
    @objc private func emitLocalLogin() {
        let userId = idTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        localLoginTapped$.accept((userId, password))
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI();
        setupConstraints();
        setupStyle()
        setupKeyboardObservers();
        bindViewModel();
        setupDismissKeyboardOnTap();
        delegate();
    }
    
    
    
}



extension LoginBottomSheetViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == idTextField {
            // ✅ ID에서 Return 누르면 PW로 포커스 이동
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            // ✅ PW에서 Return 누르면 키보드 내리고 로그인 시도
            textField.resignFirstResponder()
            localLoginButton.sendActions(for: .touchUpInside)
        }
        return true
    }
}




extension LoginBottomSheetViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
           let tokenData = credential.identityToken,
           let token = String(data: tokenData, encoding: .utf8) {

            print("✅ Apple identityToken:", token)
            appleTokenReceived$.accept(token)

        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.showAlert(message: error.localizedDescription)
        print("❌ Apple login error:", error)
    }
}


#if DEBUG
extension LoginBottomSheetViewController {
    var _test_idTextField: UITextField { idTextField }
    var _test_passwordTextField: UITextField { passwordTextField }
    var _test_localLoginButton: GuideButton { localLoginButton }
    var _test_closeButton: CircleButton { closeButton }
    var _test_googleButton: GuideButton { googleButton }
    var _test_appleButton: GuideButton { appleButton }
    var _test_scrollView: UIScrollView {scrollView}
}
#endif
