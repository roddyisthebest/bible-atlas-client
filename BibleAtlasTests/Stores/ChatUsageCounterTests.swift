import XCTest
@testable import BibleAtlas

final class ChatUsageCounterTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suiteName = "ChatUsageCounterTests.suite"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func test_initialCount_isZero() {
        let sut = ChatUsageCounter(defaults: defaults)
        XCTAssertEqual(sut.currentCount, 0)
    }

    func test_increment_bumpsCount() {
        let sut = ChatUsageCounter(defaults: defaults)
        sut.increment()
        sut.increment()
        sut.increment()
        XCTAssertEqual(sut.currentCount, 3)
    }

    func test_reset_zerosCount() {
        let sut = ChatUsageCounter(defaults: defaults)
        sut.increment()
        sut.increment()
        sut.reset()
        XCTAssertEqual(sut.currentCount, 0)
    }

    func test_countPersistsAcrossInstances() {
        ChatUsageCounter(defaults: defaults).increment()
        let sut = ChatUsageCounter(defaults: defaults)
        XCTAssertEqual(sut.currentCount, 1)
    }
}
