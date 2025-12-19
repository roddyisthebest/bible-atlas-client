//
//  ReportBottomSheetViewModelTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/7/25.
//

import XCTest
import RxSwift
import RxRelay
@testable import BibleAtlas

final class ReportBottomSheetViewModelTests: XCTestCase {
    
    private var sut: ReportBottomSheetViewModel!
    private var mockUsecase: MockReportUsecase!
    private var mockNavigator: MockBottomSheetNavigator!
    private var disposeBag: DisposeBag!
    
    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        mockUsecase = MockReportUsecase()
        mockNavigator = MockBottomSheetNavigator()
        
        sut = ReportBottomSheetViewModel(
            navigator: mockNavigator,
            reportUsecase: mockUsecase
        )
    }
    
    override func tearDown() {
        sut = nil
        mockUsecase = nil
        mockNavigator = nil
        disposeBag = nil
        super.tearDown()
    }
    
    // 공통 input 생성 헬퍼
    private func makeInput(
        viewLoaded$: PublishSubject<Void> = .init(),
        cancel$: PublishSubject<Void> = .init(),
        confirm$: PublishSubject<(String?, ReportType?)> = .init()
    ) -> (ReportBottomSheetViewModel.Input,
          PublishSubject<Void>,
          PublishSubject<(String?, ReportType?)>,
          PublishSubject<Void>) {
        
        let input = ReportBottomSheetViewModel.Input(
            viewLoaded$: viewLoaded$.asObservable(),
            cancelButtonTapped$: cancel$.asObservable(),
            confirmButtonTapped$: confirm$.asObservable()
        )
        return (input, cancel$, confirm$, viewLoaded$)
    }
    
    // Rx / Task 스케줄 반영용
    private func pump(_ sec: TimeInterval = 0.05) {
        RunLoop.current.run(until: Date().addingTimeInterval(sec))
    }
    
    
    // MARK: - Validation: comment 없음 → 에러
    
    func test_confirm_withEmptyComment_emitsCommentRequiredError_andDoesNotCallUsecase() {
        // given
        let (input, _, confirm$, _) = makeInput()
        let output = sut.transform(input: input)
        
        let exp = expectation(description: "commentRequired error emitted")
        
        output.interactionError$
            .skip(1) // initial nil skip
            .subscribe(onNext: { error in
                guard let error = error else { return }
                if case .clientError(let msg) = error {
                    XCTAssertEqual(msg, L10n.Report.commentRequired)
                    exp.fulfill()
                } else {
                    XCTFail("Expected .clientError(commentRequired), got \(error)")
                }
            })
            .disposed(by: disposeBag)
        
        // when: 공백 코멘트 + valid type
        confirm$.onNext(("   ", .other))
        
        // then
        wait(for: [exp], timeout: 1.0)
        XCTAssertTrue(mockUsecase.receivedComments.isEmpty)
        XCTAssertTrue(mockUsecase.receivedTypes.isEmpty)
    }
    
    func test_confirm_withNilComment_emitsCommentRequiredError_andDoesNotCallUsecase() {
        // given
        let (input, _, confirm$, _) = makeInput()
        let output = sut.transform(input: input)
        
        let exp = expectation(description: "commentRequired error emitted (nil)")
        
        output.interactionError$
            .skip(1)
            .subscribe(onNext: { error in
                guard let error = error else { return }
                if case .clientError(let msg) = error {
                    XCTAssertEqual(msg, L10n.Report.commentRequired)
                    exp.fulfill()
                } else {
                    XCTFail("Expected .clientError(commentRequired), got \(error)")
                }
            })
            .disposed(by: disposeBag)
        
        // when: nil comment + type 있음
        confirm$.onNext((nil, .other))
        
        // then
        wait(for: [exp], timeout: 1.0)
        XCTAssertTrue(mockUsecase.receivedComments.isEmpty)
        XCTAssertTrue(mockUsecase.receivedTypes.isEmpty)
    }
    
    
    // MARK: - Validation: type 없음 → 에러
    
    func test_confirm_withNilType_emitsTypeRequiredError_andDoesNotCallUsecase() {
        // given
        let (input, _, confirm$, _) = makeInput()
        let output = sut.transform(input: input)
        
        let exp = expectation(description: "typeRequired error emitted")
        
        output.interactionError$
            .skip(1)
            .subscribe(onNext: { error in
                guard let error = error else { return }
                if case .clientError(let msg) = error {
                    XCTAssertEqual(msg, L10n.Report.typeRequired)
                    exp.fulfill()
                } else {
                    XCTFail("Expected .clientError(typeRequired), got \(error)")
                }
            })
            .disposed(by: disposeBag)
        
        // when: comment OK, type nil
        confirm$.onNext(("버그가 있어요", nil))
        
        // then
        wait(for: [exp], timeout: 1.0)
        XCTAssertTrue(mockUsecase.receivedComments.isEmpty)
        XCTAssertTrue(mockUsecase.receivedTypes.isEmpty)
    }
    
    
    // MARK: - DI 실패: usecase == nil → diError
    
    func test_confirm_withValidInput_andNilUsecase_emitsDiError() {
        // given: usecase 없는 VM으로 새로 구성
        let vm = ReportBottomSheetViewModel(
            navigator: mockNavigator,
            reportUsecase: nil
        )
        
        let (input, _, confirm$, _) = makeInput()
        let output = vm.transform(input: input)
        
        let exp = expectation(description: "diError emitted")
        
        output.interactionError$
            .skip(1)
            .subscribe(onNext: { error in
                guard let error = error else { return }
                if case .clientError(let msg) = error {
                    XCTAssertEqual(msg, L10n.Report.diError)
                    exp.fulfill()
                } else {
                    XCTFail("Expected .clientError(diError), got \(error)")
                }
            })
            .disposed(by: disposeBag)
        
        // when
        confirm$.onNext(("정상 코멘트", .other))
        
        // then
        wait(for: [exp], timeout: 1.0)
    }
    
    
    // MARK: - 정상 플로우: usecase 성공
    
    func test_confirm_withValidInput_callsUsecase_andEmitsSuccess_onUsecaseSuccess() {
        // given
        // 실제 Report init 에 맞게 수정 필요
        let dummyReport = Report(type: .bugReport, comment: "test-comment", createdAt: "", updatedAt: "", version: 1, id: 1)
        
        mockUsecase.resultToReturn = .success(dummyReport)
        
        let (input, _, confirm$, _) = makeInput()
        let output = sut.transform(input: input)
        
        let successExp = expectation(description: "isSuccess emits true")
        
        var loadingHistory: [Bool] = []
        let loadingExp = expectation(description: "loading toggled")
        loadingExp.expectedFulfillmentCount = 3   // 초기 false + true + false
        
        output.isLoading$
            .subscribe(onNext: { value in
                loadingHistory.append(value)
                loadingExp.fulfill()
            })
            .disposed(by: disposeBag)
        
        output.isSuccess$
            .skip(1) // initial nil skip
            .subscribe(onNext: { value in
                if let v = value, v == true {
                    successExp.fulfill()
                }
            })
            .disposed(by: disposeBag)
        
        // when
        confirm$.onNext(("정상 코멘트", .other))
        
        // then
        wait(for: [loadingExp, successExp], timeout: 1.0)
        
        XCTAssertEqual(mockUsecase.receivedComments, ["정상 코멘트"])
        XCTAssertEqual(mockUsecase.receivedTypes, [.other])
        XCTAssertTrue(loadingHistory.contains(true))
        XCTAssertEqual(loadingHistory.last, false)
    }
    
    
    // MARK: - usecase 실패 → interactionError 전달
    
    func test_confirm_withValidInput_emitsInteractionError_onUsecaseFailure() {
        // given
        mockUsecase.resultToReturn = .failure(.clientError("server error"))
        
        let (input, _, confirm$, _) = makeInput()
        let output = sut.transform(input: input)
        
        let errorExp = expectation(description: "interaction error from usecase")
        
        output.interactionError$
            .skip(1)
            .subscribe(onNext: { error in
                guard let error = error else { return }
                if case .clientError(let msg) = error {
                    XCTAssertEqual(msg, "server error")
                    errorExp.fulfill()
                } else {
                    XCTFail("Expected .clientError(server error), got \(error)")
                }
            })
            .disposed(by: disposeBag)
        
        // when
        confirm$.onNext(("댓글", .other))
        
        // then
        wait(for: [errorExp], timeout: 1.0)
        XCTAssertEqual(mockUsecase.receivedComments, ["댓글"])
        XCTAssertEqual(mockUsecase.receivedTypes, [.other])
    }
    
    
    // MARK: - cancelButtonTapped → navigator.dismiss
    
    func test_cancelButtonTapped_callsNavigatorDismiss() {
        // given
        let (input, cancel$, _, _) = makeInput()
        _ = sut.transform(input: input)
        
        XCTAssertFalse(mockNavigator.isDismissed)
        
        // when
        cancel$.onNext(())
        pump(0.05)
        
        // then
        XCTAssertTrue(mockNavigator.isDismissed)
    }
}
