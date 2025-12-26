// DeepLinkToBottomSheetMapperTests.swift
// BibleAtlasTests
//
// Created by Tests on 12/25/25.

import XCTest
@testable import BibleAtlas

final class DeepLinkToBottomSheetMapperTests: XCTestCase {

    private var sut: DefaultDeepLinkToBottomSheetMapper!

    override func setUp() {
        super.setUp()
        sut = DefaultDeepLinkToBottomSheetMapper()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Basic routes

    func test_map_home_returnsHome() {
        XCTAssertEqual(sut.map(.home), .home)
    }

    func test_map_placeDetail_returnsPlaceDetailWithId() {
        let result = sut.map(.placeDetail(id: "abc"))
        XCTAssertEqual(result, .placeDetail("abc"))
    }

    // MARK: - Bible routes

    func test_map_bibleBook_valid_returnsPlacesByBible() {
        // BibleBook rawValue should match "Gen" in project enums
        let result = sut.map(.bibleBook(book: "ge"))
        XCTAssertEqual(result, .placesByBible(.Gen))
    }

    func test_map_bibleBook_invalid_returnsNil() {
        XCTAssertNil(sut.map(.bibleBook(book: "ZZZ")))
    }

    func test_map_bibleVerseDetail_valid_returnsBibleVerseDetail() {
        // Exod is a valid BibleBook rawValue in project enums
        let result = sut.map(.bibleVerseDetail(book: "exo", keyword: "12:1", placeName: "Eden"))
        XCTAssertEqual(result, .bibleVerseDetail(.Exod, "12:1", "Eden"))
    }

    // MARK: - Place type / character

    func test_map_placesByType_valid_returnsPlacesByType() {
        // PlaceTypeName rawValue should match "altar" in project enums
        let result = sut.map(.placesByType(typeName: "altar"))
        XCTAssertEqual(result, .placesByType(.altar))
    }

    func test_map_placesByType_invalid_returnsNil() {
        XCTAssertNil(sut.map(.placesByType(typeName: "invalid-type")))
    }

    func test_map_placesByCharacter_returnsPlacesByCharacter() {
        XCTAssertEqual(sut.map(.placesByCharacter(name: "David")), .placesByCharacter("David"))
    }

    // MARK: - Static routes

    func test_map_myPage_returnsMyPage() {
        XCTAssertEqual(sut.map(.myPage), .myPage)
    }

    func test_map_recentSearches_returnsRecentSearches() {
        XCTAssertEqual(sut.map(.recentSearches), .recentSearches)
    }

    func test_map_popularPlaces_returnsPopularPlaces() {
        XCTAssertEqual(sut.map(.popularPlaces), .popularPlaces)
    }

    func test_map_bibles_returnsBibles() {
        XCTAssertEqual(sut.map(.bibles), .bibles)
    }

    func test_map_placeTypes_returnsPlaceTypes() {
        XCTAssertEqual(sut.map(.placeTypes), .placeTypes)
    }

    func test_map_placeCharacters_returnsPlaceCharacters() {
        XCTAssertEqual(sut.map(.placeCharacters), .placeCharacters)
    }

    func test_map_accountManagement_returnsAccountManagement() {
        XCTAssertEqual(sut.map(.accountManagement), .accountManagement)
    }

    func test_map_report_returnsReport() {
        XCTAssertEqual(sut.map(.report), .report)
    }
}
