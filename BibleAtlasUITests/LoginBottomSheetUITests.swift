// LoginBottomSheetUITests.swift
// BibleAtlasUITests

import XCTest

final class LoginBottomSheetUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    func test_idReturn_movesFocusToPasswordField() {
        let idField = app.textFields["login_id_textfield"]
        let passwordField = app.secureTextFields["login_password_textfield"]

        // 1) 텍스트 필드가 화면에 있는지
        XCTAssertTrue(idField.waitForExistence(timeout: 3), "ID 텍스트 필드가 안 보임")
        XCTAssertTrue(passwordField.waitForExistence(timeout: 3), "PW 텍스트 필드가 안 보임")

        // 2) ID 필드 탭 + 텍스트 입력 + Return(\n)
        idField.tap()
        idField.typeText("test@example.com\n")  // \n = return

        // 3) 이후에 passwordField가 입력 가능해야 함 (포커스 이동 확인)
        // hasKeyboardFocus는 Xcode 15+ 에서만, 안되면 isHittable 정도로 타협
        #if compiler(>=5.9)
        if passwordField.responds(to: Selector(("hasKeyboardFocus"))) {
            let hasFocus = passwordField.value(forKey: "hasKeyboardFocus") as? Bool ?? false
            XCTAssertTrue(hasFocus, "Return 후에 PW 필드로 포커스가 안 옮겨짐")
        } else {
            XCTAssertTrue(passwordField.isHittable, "PW 필드가 포커스/탭 가능한 상태가 아님")
        }
        #else
        XCTAssertTrue(passwordField.isHittable, "PW 필드가 포커스/탭 가능한 상태가 아님")
        #endif
    }
    
    func test_emptyFields_showsValidationAlert() {
        let idField = app.textFields["login_id_textfield"]
        let passwordField = app.secureTextFields["login_password_textfield"]
        let loginButton = app.buttons["login_local_button"]

        XCTAssertTrue(idField.waitForExistence(timeout: 3))
        XCTAssertTrue(passwordField.waitForExistence(timeout: 3))
        XCTAssertTrue(loginButton.waitForExistence(timeout: 3))

        // 혹시 이전 값이 남아있을 수 있으니 모두 clear
        idField.tap()
        idField.clearText()
        passwordField.tap()
        passwordField.clearText()

        // 로그인 버튼 탭 (또는 pw에서 Return)
        loginButton.tap()

        // Alert 메시지 확인
        // - 타이틀을 L10n.Common.errorTitle로 잡을 수도 있고
        // - 메시지 텍스트로 잡을 수도 있음
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 2), "검증 에러 Alert가 안 떴음")

        // 메시지 텍스트 확인 (L10n.Login.invalidFormat 한국어 값으로)
        XCTAssertTrue(app.staticTexts["아이디/비밀번호를 입력해주세요."].exists)
    }


}



extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else { return }
        tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
    }
}
