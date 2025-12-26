//
//  DeepLinkHandlerTests.swift
//  BibleAtlas
//
//  Created by 배성연 on 12/26/25.
//

import XCTest
@testable import BibleAtlas

private final class MockDeepLinkParser: DeepLinkParser {
    var urlResult: DeepLink?
    var userActivityResult: DeepLink?

    private(set) var lastURL: URL?
    private(set) var lastUserActivity: NSUserActivity?

    func parse(url: URL) -> DeepLink? {
        lastURL = url
        return urlResult
    }

    func parse(userActivity: NSUserActivity) -> DeepLink? {
        lastUserActivity = userActivity
        return userActivityResult
    }
}

private final class MockMapper: DeepLinkToBottomSheetMapper {
    var mapHandler: ((DeepLink) -> BottomSheetType?)?
    private(set) var lastMappedLink: DeepLink?

    func map(_ link: DeepLink) -> BottomSheetType? {
        lastMappedLink = link
        return mapHandler?(link)
    }
}

private final class MockNavigator: BottomSheetNavigator {
    private(set) var presented: [BottomSheetType] = []
    private(set) var dismissCalled = false
    private(set) var dismissFromDetailCalled = false

    func present(_ type: BottomSheetType) {
        presented.append(type)
    }

    func dismiss(animated: Bool) {
        dismissCalled = true
    }

    func dismissFromDetail(animated: Bool) {
        dismissFromDetailCalled = true
    }

    func setPresenter(_ presenter: Presentable?) { }
}

final class DeepLinkHandlerTests: XCTestCase {

    private var parser: MockDeepLinkParser!
    private var mapper: MockMapper!
    private var navigator: MockNavigator!
    private var sut: DeepLinkHandler!

    override func setUp() {
        super.setUp()
        parser = MockDeepLinkParser()
        mapper = MockMapper()
        navigator = MockNavigator()
        sut = DeepLinkHandler(parser: parser, mapper: mapper, navigator: navigator)
    }

    override func tearDown() {
        sut = nil
        navigator = nil
        mapper = nil
        parser = nil
        super.tearDown()
    }

    // MARK: - handle(url:)

    func test_handleURL_whenParserAndMapperSucceed_presentsMappedType() {
        // Given
        parser.urlResult = .placeDetail(id: "ABC")
        mapper.mapHandler = { link in
            if case .placeDetail(let id) = link { return .placeDetail(id) }
            return nil
        }

        // When
        sut.handle(url: URL(string: "https://example.com/anything")!)

        // Then
        XCTAssertEqual(navigator.presented, [.placeDetail("ABC")])
    }

    func test_handleURL_whenParserReturnsNil_doesNotPresent() {
        // Given
        parser.urlResult = nil
        mapper.mapHandler = { _ in XCTFail("Mapper should not be called when parser returns nil"); return nil }

        // When
        sut.handle(url: URL(string: "https://example.com/anything")!)

        // Then
        XCTAssertTrue(navigator.presented.isEmpty)
    }

    func test_handleURL_whenMapperReturnsNil_doesNotPresent() {
        // Given
        parser.urlResult = .home
        mapper.mapHandler = { _ in nil }

        // When
        sut.handle(url: URL(string: "https://example.com/anything")!)

        // Then
        XCTAssertTrue(navigator.presented.isEmpty)
    }

    // MARK: - handle(userActivity:)

    func test_handleUserActivity_whenParserAndMapperSucceed_presentsMappedType() {
        // Given
        parser.userActivityResult = .bibleVerseDetail(book: "Exod", keyword: "12:1", placeName: "Nile")
        mapper.mapHandler = { link in
            if case let .bibleVerseDetail(book, keyword, placeName) = link {
                return .bibleVerseDetail(.Exod, keyword, placeName)
            }
            return nil
        }

        let ua = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)

        // When
        sut.handle(userActivity: ua)

        // Then
        XCTAssertEqual(navigator.presented, [.bibleVerseDetail(.Exod, "12:1", "Nile")])
    }

    func test_handleUserActivity_whenParserReturnsNil_doesNotPresent() {
        // Given
        parser.userActivityResult = nil
        mapper.mapHandler = { _ in XCTFail("Mapper should not be called when parser returns nil"); return nil }

        let ua = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)

        // When
        sut.handle(userActivity: ua)

        // Then
        XCTAssertTrue(navigator.presented.isEmpty)
    }

    func test_handleUserActivity_whenMapperReturnsNil_doesNotPresent() {
        // Given
        parser.userActivityResult = .myPage
        mapper.mapHandler = { _ in nil }

        let ua = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)

        // When
        sut.handle(userActivity: ua)

        // Then
        XCTAssertTrue(navigator.presented.isEmpty)
    }
}
