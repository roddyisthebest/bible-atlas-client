//
//  Pagination.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/25/25.
//

import Foundation

struct Pagination {
    private(set) var page: Int = 0
    private(set) var hasMore: Bool = true
    let pageSize: Int

    init(pageSize: Int = 10) {
        self.pageSize = pageSize
    }

    mutating func reset() {
        self.page = 0
        self.hasMore = true
    }

    mutating func update(total: Int) {
        let totalPages = Int(ceil(Double(total) / Double(pageSize)))
        self.hasMore = self.page + 1 < totalPages
    }

    mutating func advanceIfPossible() -> Bool {
        guard hasMore else { return false }
        self.page += 1
        return true
    }
}

