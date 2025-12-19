//
//  LoginBottomSheetViewControllerTests.swift
//  BibleAtlasTests
//

import XCTest
import RxSwift
import AuthenticationServices
@testable import BibleAtlas

final class LoginBottomSheetViewControllerTests: XCTestCase {
    
    private var sut: LoginBottomSheetViewController!
    private var mockVM: MockLoginBottomSheetViewModel!
    private var window: UIWindow!
    
    override func setUp() {
        super.setUp()
        mockVM = MockLoginBottomSheetViewModel()
        sut = LoginBottomSheetViewController(loginBottomSheetViewModel: mockVM)
        
        // viewDidLoad + bindViewModel
        _ = sut.view
        
        // 🔥 alert / present 테스트 가능하게 window에 붙이기
        window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        window.rootViewController?.present(sut, animated: false, completion: nil)
        pump()
    }
    
    override func tearDown() {
        window = nil
        sut = nil
        mockVM = nil
        super.tearDown()
    }
    
    private func pump(_ seconds: TimeInterval = 0.05) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }
    
    // MARK: - viewDidLoad → transform 호출
    
    func test_viewDidLoad_callsTransformOnce() {
        XCTAssertEqual(mockVM.transformCallCount, 1)
    }
    
    // MARK: - Local 로그인 버튼 → ViewModel로 값 전달
    
    func test_localLoginButtonTap_sendsTrimmedCredentialsToViewModel() {
        // given
        sut._test_idTextField.text = "  user@test.com  "
        sut._test_passwordTextField.text = "  pass123  "
        
        // when
        sut._test_localLoginButton.sendActions(for: .touchUpInside)
        pump()
        
        // then
        guard let last = mockVM.receivedLocalLoginTuples.last else {
            XCTFail("local login tuples should not be empty")
            return
        }
        
        XCTAssertEqual(last.0, "user@test.com")
        XCTAssertEqual(last.1, "pass123")
    }
    
    // MARK: - Close 버튼 → ViewModel로 이벤트 전달
    
    func test_closeButtonTap_triggersCloseOnViewModel() {
        // when
        sut._test_closeButton.sendActions(for: .touchUpInside)
        pump()
        
        // then
        XCTAssertEqual(mockVM.closeButtonTapCount, 1)
    }
    
    // MARK: - localLoading 바인딩
    
    func test_localLoadingBinding_doesNotCrash() {
        mockVM.localLoadingRelay.accept(true)
        pump()
        mockVM.localLoadingRelay.accept(false)
        pump()
        
        XCTAssertTrue(true) // 크래시만 안 나면 OK
    }
    
    // MARK: - googleLoading / appleLoading 바인딩
    
    func test_googleLoadingBinding_doesNotCrash() {
        mockVM.googleLoadingRelay.accept(true)
        pump()
        mockVM.googleLoadingRelay.accept(false)
        pump()
        
        XCTAssertTrue(true)
    }
    
    func test_appleLoadingBinding_doesNotCrash() {
        mockVM.appleLoadingRelay.accept(true)
        pump()
        mockVM.appleLoadingRelay.accept(false)
        pump()
        
        XCTAssertTrue(true)
    }
    
    // MARK: - error 바인딩 → alert
    
    func test_errorBinding_presentsAlertWithErrorDescription() {
        // given
        let error = NetworkError.clientError("test-error")
        
        // when
        mockVM.errorSubject.onNext(error)
        pump(0.1)
        
        // then
        guard let alert = sut.presentedViewController as? UIAlertController else {
            return XCTFail("Expected UIAlertController to be presented")
        }
        
        XCTAssertEqual(alert.title, L10n.Common.errorTitle)
        XCTAssertTrue(alert.message?.contains("test-error") ?? false)
    }
    
    // MARK: - Google 버튼 → FirebaseApp 없음일 때 guard에서 조용히 리턴
    
    func test_googleButtonTap_whenNoFirebaseApp_doesNotCrash() {
        // FirebaseApp 설정 안 되어 있으면 guard 에서 바로 return
        sut._test_googleButton.sendActions(for: .touchUpInside)
        pump()
        
        // 크래시만 안 나면 OK (guard 경로는 타짐)
        XCTAssertTrue(true)
    }
    
    // MARK: - Apple 에러 핸들러 직접 호출 → alert
    
    func test_appleAuthorizationError_presentsAlert() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        let controller = ASAuthorizationController(authorizationRequests: [request])
        
        struct DummyError: LocalizedError {
            var errorDescription: String? { "apple-failed" }
        }
        let err = DummyError()
        
        sut.authorizationController(controller: controller, didCompleteWithError: err)
        pump(0.1)
        
        guard let alert = sut.presentedViewController as? UIAlertController else {
            return XCTFail("Expected UIAlertController for Apple error")
        }
            
        print("alert.message =", alert.message as Any)
        XCTAssertEqual(alert.title, L10n.Common.errorTitle)
        XCTAssertTrue(alert.message?.contains("apple-failed") ?? false)
    }
    
    // MARK: - textFieldShouldReturn 로직
    
    func test_textFieldReturn_fromId_movesFocusToPassword() {
        let idField = sut._test_idTextField
        let pwField = sut._test_passwordTextField
        
        idField.becomeFirstResponder()
        _ = sut.textFieldShouldReturn(idField)
        pump()
        
        XCTAssertTrue(pwField.isFirstResponder)
    }
    
    func test_textFieldReturn_fromPassword_triggersLocalLogin() {
        // given
        sut._test_idTextField.text = "user"
        sut._test_passwordTextField.text = "pw"
        
        let initialCount = mockVM.receivedLocalLoginTuples.count
        
        let pwField = sut._test_passwordTextField
        pwField.becomeFirstResponder()
        
        // when
        _ = sut.textFieldShouldReturn(pwField)
        pump()
        
        // then
        XCTAssertGreaterThan(mockVM.receivedLocalLoginTuples.count, initialCount)
    }
    
    // MARK: - 키보드 show/hide → scrollView inset 조정 (KVC로 접근)
    
    func test_keyboardNotifications_adjustScrollInsets() {
        // given
        let keyboardFrame = CGRect(
            x: 0,
            y: sut.view.bounds.height - 100,
            width: sut.view.bounds.width,
            height: 100
        )

        let userInfo: [AnyHashable: Any] = [
            UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: keyboardFrame),
            UIResponder.keyboardAnimationDurationUserInfoKey: 0.01,
            // 🔥 UInt 또는 NSNumber로 넣어줘야 함
            UIResponder.keyboardAnimationCurveUserInfoKey: UInt(UIView.AnimationCurve.easeInOut.rawValue)
            // 또는: NSNumber(value: UIView.AnimationCurve.easeInOut.rawValue)
        ]

        // when: willShow
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillShowNotification,
            object: nil,
            userInfo: userInfo
        )
        pump(0.05)

        // then: bottom inset > 0
        XCTAssertGreaterThan(sut._test_scrollView.contentInset.bottom, 0)

        // when: willHide
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillHideNotification,
            object: nil,
            userInfo: userInfo
        )
        pump(0.05)

        // then: 다시 0
        XCTAssertEqual(sut._test_scrollView.contentInset.bottom, 0)
    }

}
