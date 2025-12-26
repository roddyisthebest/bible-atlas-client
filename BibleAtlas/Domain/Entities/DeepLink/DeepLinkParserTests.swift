// DeepLinkParserTests.swift
// BibleAtlasTests
//
// Created by Tests on 12/25/25.

import XCTest
@testable import BibleAtlas

final class DeepLinkParserTests: XCTestCase {

    private var sut: DefaultDeepLinkParser!

    override func setUp() {
        super.setUp()
        sut = DefaultDeepLinkParser()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Scheme handling

    func test_parse_invalidScheme_returnsNil() {
        let url = URL(string: "ftp://bibleatlas.app/home")!
        XCTAssertNil(sut.parse(url: url))
    }

    func test_parse_noPath_returnsHome() {
        let url = URL(string: "bibleatlas://")!
        let result = sut.parse(url: url)
        guard case .home? = result else { return XCTFail("Expected .home for empty path") }
    }

    // MARK: - Home

    func test_parse_home_customScheme_returnsHome() {
        let url = URL(string: "bibleatlas://app/home")!
        let result = sut.parse(url: url)
        guard case .home? = result else { return XCTFail("Expected .home") }
    }

    func test_parse_home_https_returnsHome() {
        let url = URL(string: "https://bibleatlas.app/home")!
        let result = sut.parse(url: url)
        guard case .home? = result else { return XCTFail("Expected .home") }
    }

    // MARK: - Place detail

    func test_parse_placeDetail_returnsPlaceDetail() {
        let url = URL(string: "https://example.com/place/ABC123")!
        let result = sut.parse(url: url)
        guard case let .placeDetail(id)? = result else { return XCTFail("Expected .placeDetail") }
        XCTAssertEqual(id, "ABC123")
    }

    func test_parse_placeDetail_missingId_returnsNil() {
        let url = URL(string: "https://example.com/place")!
        XCTAssertNil(sut.parse(url: url))
    }

    // MARK: - Bible book

    func test_parse_bibleBook_returnsBibleBook() {
        let url = URL(string: "https://example.com/bible/Gen")!
        let result = sut.parse(url: url)
        guard case let .bibleBook(book)? = result else { return XCTFail("Expected .bibleBook") }
        XCTAssertEqual(book, "Gen")
    }

    func test_parse_bibleBook_missing_returnsNil() {
        let url = URL(string: "https://example.com/bible")!
        XCTAssertNil(sut.parse(url: url))
    }

    // MARK: - Verse detail

    func test_parse_bibleVerseDetail_returnsBookKeywordAndPlace() {
        let url = URL(string: "https://example.com/verse/Exod?keyword=12:1&place=Nile")!
        let result = sut.parse(url: url)
        guard case let .bibleVerseDetail(book, keyword, place)? = result else { return XCTFail("Expected .bibleVerseDetail") }
        XCTAssertEqual(book, "Exod")
        XCTAssertEqual(keyword, "12:1")
        XCTAssertEqual(place, "Nile")
    }

    func test_parse_bibleVerseDetail_withoutPlace_allowsNilPlace() {
        let url = URL(string: "https://example.com/verse/Exod?keyword=12:1")!
        let result = sut.parse(url: url)
        guard case let .bibleVerseDetail(book, keyword, place)? = result else { return XCTFail("Expected .bibleVerseDetail") }
        XCTAssertEqual(book, "Exod")
        XCTAssertEqual(keyword, "12:1")
        XCTAssertNil(place)
    }

    func test_parse_bibleVerseDetail_missingBook_returnsNil() {
        let url = URL(string: "https://example.com/verse")!
        XCTAssertNil(sut.parse(url: url))
    }

    // MARK: - Places by type / character

    func test_parse_placesByType_returnsTypeName() {
        let url = URL(string: "https://example.com/type/altar")!
        let result = sut.parse(url: url)
        guard case let .placesByType(typeName)? = result else { return XCTFail("Expected .placesByType") }
        XCTAssertEqual(typeName, "altar")
    }

    func test_parse_placesByType_missing_returnsNil() {
        let url = URL(string: "https://example.com/type")!
        XCTAssertNil(sut.parse(url: url))
    }

    func test_parse_placesByCharacter_returnsName() {
        let url = URL(string: "https://example.com/character/David")!
        let result = sut.parse(url: url)
        guard case let .placesByCharacter(name)? = result else { return XCTFail("Expected .placesByCharacter") }
        XCTAssertEqual(name, "David")
    }

    func test_parse_placesByCharacter_missing_returnsNil() {
        let url = URL(string: "https://example.com/character")!
        XCTAssertNil(sut.parse(url: url))
    }

    // MARK: - Static routes

    func test_parse_staticRoutes_returnExpectedLinks() {
        let cases: [(String, (DeepLink?) -> Bool)] = [
            ("mypage", { if case .myPage? = $0 { return true } else { return false } }),
            ("recent", { if case .recentSearches? = $0 { return true } else { return false } }),
            ("popular", { if case .popularPlaces? = $0 { return true } else { return false } }),
            ("bibles", { if case .bibles? = $0 { return true } else { return false } }),
            ("place-types", { if case .placeTypes? = $0 { return true } else { return false } }),
            ("place-characters", { if case .placeCharacters? = $0 { return true } else { return false } }),
            ("account", { if case .accountManagement? = $0 { return true } else { return false } }),
            ("report", { if case .report? = $0 { return true } else { return false } })
        ]

        for (path, matcher) in cases {
            let url = URL(string: "https://example.com/\(path)")!
            XCTAssertTrue(matcher(sut.parse(url: url)), "Expected deep link for path: \(path)")
        }
    }

    func test_parse_unknownPath_returnsNil() {
        let url = URL(string: "https://example.com/unknown/route")!
        XCTAssertNil(sut.parse(url: url))
    }

    // MARK: - NSUserActivity

    func test_parse_userActivity_browsingWeb_parsesFromURL() {
        let url = URL(string: "https://example.com/place/XYZ")!
        let ua = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        ua.webpageURL = url

        let result = sut.parse(userActivity: ua)
        guard case let .placeDetail(id)? = result else { return XCTFail("Expected .placeDetail from userActivity") }
        XCTAssertEqual(id, "XYZ")
    }

    func test_parse_userActivity_nonWeb_returnsNil() {
        let ua = NSUserActivity(activityType: "com.example.custom")
        XCTAssertNil(sut.parse(userActivity: ua))
    }
}
