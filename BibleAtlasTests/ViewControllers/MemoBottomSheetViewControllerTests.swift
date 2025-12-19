//
//  MemoBottomSheetViewControllerTests.swift
//  BibleAtlasTests
//

import XCTest
@testable import BibleAtlas

final class TestableMemoBottomSheetViewController: MemoBottomSheetViewController {

    var lastPresentedAlert: UIAlertController?

    override func present(_ viewControllerToPresent: UIViewController,
                          animated flag: Bool,
                          completion: (() -> Void)? = nil) {

        if let alert = viewControllerToPresent as? UIAlertController {
            lastPresentedAlert = alert
        }
        // 실제 UI 띄울 필요는 없으니 super 호출은 생략 가능
        completion?()
    }
}

final class MemoBottomSheetViewControllerTests: XCTestCase {

    private var sut: MemoBottomSheetViewController!
    private var mockVM: MockMemoBottomSheetViewModel!

    override func setUp() {
        super.setUp()
        mockVM = MockMemoBottomSheetViewModel()
        sut = TestableMemoBottomSheetViewController(memoBottomSheetViewModel: mockVM)

        _ = sut.view   // viewDidLoad + bindViewModel + viewLoaded$.accept
        pump()
    }

    override func tearDown() {
        sut = nil
        mockVM = nil
        super.tearDown()
    }

    private func pump(_ seconds: TimeInterval = 0.05) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    // MARK: - Life cycle / viewLoaded$

    func test_viewDidLoad_triggersViewLoadedOnViewModel() {
        XCTAssertEqual(mockVM.viewLoadedCallCount, 1)
    }

    // MARK: - isLoading / loadError / memo 상태에 따른 UI

    func test_loadingState_showsLoading_hidesTextAndDeleteAndError() {
        // given
        mockVM.isLoadingSubject.onNext(true)
        mockVM.loadErrorSubject.accept(nil)
        mockVM.memoSubject.onNext("")
        pump()

        // then
        XCTAssertFalse(sut._test_loadingView.isHidden, "로딩 중에는 loadingView가 보여야 함")
        XCTAssertTrue(sut._test_descriptionTextView.isHidden, "로딩 중에는 메모 텍스트뷰 숨김")
        XCTAssertTrue(sut._test_deleteMemoButton.isHidden, "로딩 중에는 삭제 버튼 숨김")
        XCTAssertTrue(sut._test_errorRetryView.isHidden, "로딩 중에는 에러뷰 숨김")
    }

    func test_loadError_showsErrorRetryView_andHidesTextAndDeleteAndLoading_andDisablesConfirmButton() {
        // given
        mockVM.isLoadingSubject.onNext(false)
        mockVM.loadErrorSubject.accept(.clientError("테스트 에러"))
        mockVM.memoSubject.onNext("")
        pump()

        // then
        XCTAssertFalse(sut._test_errorRetryView.isHidden, "에러 시 errorRetryView 표시")
        XCTAssertTrue(sut._test_descriptionTextView.isHidden, "에러 시 텍스트뷰 숨김")
        XCTAssertTrue(sut._test_deleteMemoButton.isHidden, "에러 시 삭제 버튼 숨김")
        XCTAssertTrue(sut._test_loadingView.isHidden, "에러 시 로딩뷰 숨김")
        XCTAssertFalse(sut._test_confirmButton.isEnabled, "에러 시 확인 버튼 비활성화")
    }

    func test_initialLoad_withEmptyMemo_showsAddMode() {
        // given: 로딩 종료, 에러 없음, memo = ""
        mockVM.isLoadingSubject.onNext(false)
        mockVM.loadErrorSubject.accept(nil)
        mockVM.memoSubject.onNext("")
        pump()

        // then
        XCTAssertFalse(sut._test_descriptionTextView.isHidden, "메모 입력 가능해야 함")
        XCTAssertTrue(sut._test_deleteMemoButton.isHidden, "메모 없으면 삭제 버튼 숨김")
        XCTAssertEqual(sut._test_headerLabel.text, L10n.Memo.addTitle)
    }

    func test_initialLoad_withExistingMemo_showsUpdateMode() {
        // given: 로딩 종료, 에러 없음, memo 존재
        let memoText = "기존 메모입니다."
        mockVM.isLoadingSubject.onNext(false)
        mockVM.loadErrorSubject.accept(nil)
        mockVM.memoSubject.onNext(memoText)
        pump()

        // then
        XCTAssertFalse(sut._test_descriptionTextView.isHidden)
        XCTAssertFalse(sut._test_deleteMemoButton.isHidden, "메모 있으면 삭제 버튼 보여야 함")
        XCTAssertEqual(sut._test_descriptionTextView.text, memoText)
        XCTAssertEqual(sut._test_headerLabel.text, L10n.Memo.updateTitle)
    }

    // MARK: - isCreatingOrUpdating 바인딩

    func test_isCreatingOrUpdating_true_hidesConfirmButton_andDisablesDelete() {
        // given
        mockVM.isCreatingOrUpdatingSubject.onNext(true)
        pump()

        // then
        XCTAssertTrue(sut._test_confirmButton.isHidden, "생성/수정 중에는 확인 버튼 숨김")
        XCTAssertFalse(sut._test_deleteMemoButton.isEnabled, "생성/수정 중에는 삭제 버튼 비활성화")
        // confirmLoadingView는 isHidden 설정을 안 바꾸지만, start()가 호출되는지만으로는 테스트 어렵고,
        // 여기서는 버튼 상태만 체크해도 커버리지 충분.
    }

    func test_isCreatingOrUpdating_false_showsConfirmButton_andEnablesDelete() {
        // given
        mockVM.isCreatingOrUpdatingSubject.onNext(false)
        pump()

        // then
        XCTAssertFalse(sut._test_confirmButton.isHidden)
        XCTAssertTrue(sut._test_deleteMemoButton.isEnabled)
        XCTAssertEqual(sut._test_confirmButton.title(for: .normal), L10n.Common.done)
    }

    // MARK: - isDeleting 바인딩

    func test_isDeleting_true_disablesConfirmButton() {
        mockVM.isDeletingSubject.onNext(true)
        pump()

        XCTAssertFalse(sut._test_confirmButton.isEnabled, "삭제 중일 때 확인 버튼 비활성화")
    }

    func test_isDeleting_false_enablesConfirmButton() {
        mockVM.isDeletingSubject.onNext(false)
        pump()

        XCTAssertTrue(sut._test_confirmButton.isEnabled, "삭제 중이 아니면 확인 버튼 활성화")
    }

    // MARK: - cancel / confirm / delete / refetch 이벤트 전달

    func test_cancelButtonTap_triggersViewModelCancel() {
        sut._test_cancelButton.sendActions(for: .touchUpInside)
        pump()

        XCTAssertEqual(mockVM.cancelButtonTapCount, 1)
    }

    func test_confirmButtonTap_sendsTextToViewModel() {
        // given
        sut._test_descriptionTextView.text = "테스트 메모 내용"
        pump()

        // when
        sut._test_confirmButton.sendActions(for: .touchUpInside)
        pump()

        XCTAssertEqual(mockVM.confirmButtonTapTexts.count, 1)
        XCTAssertEqual(mockVM.confirmButtonTapTexts.first, "테스트 메모 내용")
    }

    func test_deleteButtonTap_triggersViewModelDelete() {
        sut._test_deleteMemoButton.sendActions(for: .touchUpInside)
        pump()

        XCTAssertEqual(mockVM.deleteButtonTapCount, 1)
    }

    func test_errorRetryViewRefetchTap_triggersViewModelRefetch() {
        sut._test_errorRetryView.refetchTapped$.accept(())
        pump()

        XCTAssertEqual(mockVM.refetchButtonTapCount, 1)
    }

}
