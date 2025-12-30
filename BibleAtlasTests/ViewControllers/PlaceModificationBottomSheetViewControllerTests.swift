// PlaceModificationBottomSheetViewControllerTests.swift
@testable import BibleAtlas
import XCTest
import RxSwift

final class PlaceModificationBottomSheetViewControllerTests: XCTestCase {
    
    private var mockViewModel: MockPlaceModificationBottomSheetViewModel!
    private var viewController: PlaceModificationBottomSheetViewController!
    private var window: UIWindow!   // 👈 alert 띄우려면 필요

    override func setUp() {
        super.setUp()
        mockViewModel = MockPlaceModificationBottomSheetViewModel()
        viewController = PlaceModificationBottomSheetViewController(vm: mockViewModel)

        // viewDidLoad 강제
        _ = viewController.view

        // 👇 window에 붙여서 view.window != nil 되게 해줌
        window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        window.rootViewController?.present(viewController, animated: false, completion: nil)
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))
    }
    
    override func tearDown() {
        window = nil
        viewController = nil
        mockViewModel = nil
        super.tearDown()
    }
    
    private func pump(_ sec: TimeInterval = 0.01) {
        RunLoop.current.run(until: Date().addingTimeInterval(sec))
    }
    
    func test_viewDidLoad_callsTransformOnViewModel() {
        XCTAssertTrue(mockViewModel.transformCalled)
    }
    
    func test_cancelButtonTap_sendsEventToViewModel() {
        // given
        let cancelButton = viewController.test_cancelButton
        
        // when
        cancelButton.sendActions(for: .touchUpInside)
        
        // then
        XCTAssertEqual(mockViewModel.cancelTapCount, 1)
    }
    
    func test_confirmButtonTap_triggersViewModelConfirm() {
        // given
        let confirmButton = viewController.test_confirmButton
        let textView = viewController.test_descriptionTextView

        textView.text = "  수정 제안입니다  "

        // when
        confirmButton.sendActions(for: .touchUpInside)

        // then
        XCTAssertEqual(mockViewModel.confirmTapCount, 1)
    }

    func test_isCreating_changesButtonVisibility_andTitle() {
        let confirmButton = viewController.test_confirmButton
        
        // when: 로딩 시작
        mockViewModel.isCreatingSubject.onNext(true)
        pump()

        // then
        XCTAssertTrue(confirmButton.isHidden)
        XCTAssertNil(confirmButton.title(for: .normal))   // 제목 날아감
        
        // when: 로딩 종료
        mockViewModel.isCreatingSubject.onNext(false)
        pump()

        // then
        XCTAssertFalse(confirmButton.isHidden)
        XCTAssertEqual(confirmButton.title(for: .normal), L10n.Common.ok)
    }

    // MARK: - interactionError$ 분기 테스트

    func test_interactionError_withNil_doesNotPresentAlert() {
        // when
        mockViewModel.interactionErrorSubject.onNext(nil)
        pump()

        // then
        // 아무 alert도 안 떠야 함
        XCTAssertNil(viewController.presentedViewController)
    }

    func test_interactionError_withError_presentsAlert() {
        // given
        let error = NetworkError.clientError("test-error")

        // when
        mockViewModel.interactionErrorSubject.onNext(error)
        pump(0.5)

        // then
        guard let alert = viewController.presentedViewController as? UIAlertController else {
            return XCTFail("Expected UIAlertController to be presented")
        }
        XCTAssertEqual(alert.message, error.description)
    }

    // MARK: - isSuccess$ 분기 테스트

    func test_isSuccess_true_presentsSuccessAlert() {
        // when
        mockViewModel.isSuccessSubject.onNext(true)
        pump(0.5)

        // then
        guard let alert = viewController.presentedViewController as? UIAlertController else {
            return XCTFail("Expected success UIAlertController to be presented")
        }
        XCTAssertEqual(alert.message, L10n.PlaceModification.success)
    }

    // 성공 false / nil 들어오면 아무 일도 안 일어나는지 확인 (guard + if 분기)
    func test_isSuccess_false_doesNothing() {
        // when
        mockViewModel.isSuccessSubject.onNext(false)
        pump()

        XCTAssertNil(viewController.presentedViewController)
    }

    func test_isSuccess_nil_doesNothing() {
        // when
        mockViewModel.isSuccessSubject.onNext(nil)
        pump()

        XCTAssertNil(viewController.presentedViewController)
    }

    // MARK: - 기본 UI 설정도 살짝 긁어주기 (accessibilityLabel 등)

    func test_descriptionTextView_hasPlaceholderAccessibilityLabel() {
        let tv = viewController.test_descriptionTextView
        XCTAssertEqual(tv.accessibilityLabel, L10n.PlaceModification.placeholder)
    }
}
