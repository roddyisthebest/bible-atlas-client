//
//  PaginationTest.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 5/25/25.
//

import XCTest
@testable import BibleAtlas

final class PaginationTests: XCTestCase {
    
    func test_initialState() {
        let pagination = Pagination(pageSize: 10)
        XCTAssertEqual(pagination.page, 0)
        XCTAssertTrue(pagination.hasMore)
    }

    func test_advanceIfPossible_whenHasMore_isTrue() {
        var pagination = Pagination(pageSize: 10)
        let advanced = pagination.advanceIfPossible()
        XCTAssertTrue(advanced)
        XCTAssertEqual(pagination.page, 1)
    }

    func test_advanceIfPossible_whenHasMore_isFalse() {
        var pagination = Pagination(pageSize: 10)
        pagination.update(total: 10) // 한 페이지만 있음
        _ = pagination.advanceIfPossible() // page = 0

        let canAdvance = pagination.advanceIfPossible()
        XCTAssertFalse(canAdvance)
        XCTAssertEqual(pagination.page, 0) // 그대로
    }

    func test_update_hasMore_true_whenMorePagesExist() {
        var pagination = Pagination(pageSize: 10)
        pagination.update(total: 25)
        XCTAssertTrue(pagination.hasMore)
    }

    func test_update_hasMore_false_whenNoMorePages() {
        var pagination = Pagination(pageSize: 10)
        pagination.update(total: 10)
        XCTAssertFalse(pagination.hasMore)
    }

    func test_reset_setsInitialState() {
        var pagination = Pagination(pageSize: 10)
        _ = pagination.advanceIfPossible()
        pagination.update(total: 5)
        pagination.reset()
        
        XCTAssertEqual(pagination.page, 0)
        XCTAssertTrue(pagination.hasMore)
    }
}
