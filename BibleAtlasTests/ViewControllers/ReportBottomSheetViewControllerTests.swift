//
//  ReportBottomSheetViewControllerTests.swift
//  BibleAtlasTests
//

import XCTest
import RxSwift
@testable import BibleAtlas



// 🔹 Alert 캡쳐용 서브클래스
final class TestReportBottomSheetViewController: ReportBottomSheetViewController {
    var lastPresentedAlert: UIAlertController?

    override func present(_ viewControllerToPresent: UIViewController,
                          animated flag: Bool,
                          completion: (() -> Void)? = nil) {
        
        print("present!")
        if let alert = viewControllerToPresent as? UIAlertController {
            lastPresentedAlert = alert
        }
        // 실제 present는 안 해도 됨 (테스트니까)
        completion?()
    }
}


final class ReportBottomSheetViewControllerTests: XCTestCase {
    
    private var sut: TestReportBottomSheetViewController!
    private var mockVM: MockReportBottomSheetViewModel!
    private var disposeBag: DisposeBag!
    
    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        mockVM = MockReportBottomSheetViewModel()
        sut = TestReportBottomSheetViewController(reportBottomSheetViewModel: mockVM)
        
        // viewDidLoad 트리거
        _ = sut.view
        pump()
    }
    
    override func tearDown() {
        sut = nil
        mockVM = nil
        disposeBag = nil
        super.tearDown()
    }
    
    private func pump(_ sec: TimeInterval = 0.05) {
        RunLoop.current.run(until: Date().addingTimeInterval(sec))
    }
    
    // MARK: - cancel 버튼 탭 → ViewModel cancel 이벤트 전달
    
    func test_cancelButtonTap_sendsCancelToViewModel() {
        // given
        XCTAssertEqual(mockVM.receivedCancelTapCount, 0)
        
        // when
        sut._test_cancelButton.sendActions(for: .touchUpInside)
        pump()
        
        // then
        XCTAssertEqual(mockVM.receivedCancelTapCount, 1)
    }
    
    // MARK: - confirm 버튼 탭 → comment/type 전달
    
    func test_confirmButtonTap_sendsCommentAndTypeToViewModel() {
        // given
        let comment = "테스트 코멘트"
        
        // ⚠️ textView.text 만 바꾸면 Rx가 모름 → rx.text.onNext 로 흘려보내기
        sut._test_textView.rx.text.onNext(comment)
        pump()
        
        XCTAssertTrue(mockVM.receivedConfirmPayloads.isEmpty)
        
        // when
        sut._test_confirmButton.sendActions(for: .touchUpInside)
        pump()
        
        // then
        XCTAssertEqual(mockVM.receivedConfirmPayloads.count, 1)
        let first = mockVM.receivedConfirmPayloads[0]
        XCTAssertEqual(first.0, comment)
        // selectedReportType$ 초기값은 nil 이라 type 도 nil
        XCTAssertNil(first.1)
    }
    
    // MARK: - isLoading 바인딩: confirm 버튼 / 로딩뷰 토글
    
    func test_isLoading_togglesConfirmButton_andLoadingView() {
        // given
        let confirmButton = sut._test_confirmButton
        let loadingView = sut._test_confirmLoadingView
        
        // 초기 상태
        XCTAssertFalse(confirmButton.isHidden)
        XCTAssertTrue(confirmButton.isUserInteractionEnabled)
        XCTAssertTrue(loadingView.isHidden)
        
        // when: 로딩 시작
        mockVM.isLoadingSubject.onNext(true)
        pump(0.1)
        
        // then
        XCTAssertTrue(confirmButton.isHidden)
        XCTAssertFalse(confirmButton.isUserInteractionEnabled)
        XCTAssertFalse(loadingView.isHidden)
        
        // when: 로딩 종료
        mockVM.isLoadingSubject.onNext(false)
        pump(0.1)
        
        // then
        XCTAssertFalse(confirmButton.isHidden)
        XCTAssertTrue(confirmButton.isUserInteractionEnabled)
        XCTAssertTrue(loadingView.isHidden)
    }
    
    // MARK: - interactionError$ → 에러 alert 표시
    
    func test_interactionError_emits_showsErrorAlert() {
        // given
        XCTAssertNil(sut.lastPresentedAlert)
        
        // when
        mockVM.interactionErrorSubject.onNext(.clientError("테스트 에러"))
        pump(0.1)
        
        // then
        XCTAssertNotNil(sut.lastPresentedAlert)
        XCTAssertEqual(sut.lastPresentedAlert?.title, L10n.Common.errorTitle) // 타이틀까지 보고 싶으면 여기 조정
    }
    

    

}
