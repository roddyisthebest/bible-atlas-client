//
//  RecentSearchServiceTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/10/25.
//

import XCTest
import CoreData
import RxSwift
import RxBlocking
@testable import BibleAtlas

final class RecentSearchServiceTests: XCTestCase {

    private var container: NSPersistentContainer!
    private var context: NSManagedObjectContext!
    private var sut: RecentSearchService!
    private var disposeBag: DisposeBag!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()

        // In-Memory Persistent Container
        container = NSPersistentContainer(name: "BibleAtlas")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        let exp = expectation(description: "Load persistent stores")
        container.loadPersistentStores { _, error in
            if let error = error {
                XCTFail("Failed to load in-memory store: \(error)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)

        context = container.viewContext
        sut = RecentSearchService(context: context)
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        disposeBag = nil
        sut = nil
        context = nil
        container = nil
        super.tearDown()
    }

    // MARK: - Helpers

    @discardableResult
    private func insertRecent(
        id: String,
        name: String,
        koreanName: String,
        type: String,
        timestamp: Date
    ) throws -> RecentSearchEntity {
        let entity = RecentSearchEntity(context: context)
        entity.id = id
        entity.name = name
        entity.koreanName = koreanName
        entity.type = type
        entity.timestamp = timestamp
        try context.save()
        return entity
    }

    private func fetchAllEntities() throws -> [RecentSearchEntity] {
        let request: NSFetchRequest<RecentSearchEntity> = RecentSearchEntity.fetchRequest()
        return try context.fetch(request)
    }

    // MARK: - fetch(limit:page:)

    func test_fetch_returnsPagedItemsSortedByTimestampDesc() throws {
        // given
        let now = Date()
        let older = now.addingTimeInterval(-100)
        let oldest = now.addingTimeInterval(-200)

        try insertRecent(id: "1", name: "A", koreanName: "가", type: "CITY", timestamp: oldest)
        try insertRecent(id: "2", name: "B", koreanName: "나", type: "RIVER", timestamp: now)
        try insertRecent(id: "3", name: "C", koreanName: "다", type: "MOUNTAIN", timestamp: older)

        // when: page 0, limit 2 → 최신순 2개 (id 2, 3)
        let result = sut.fetch(limit: 2, page: 0)

        // then
        switch result {
        case .success(let fetchResult):
            XCTAssertEqual(fetchResult.total, 3)
            XCTAssertEqual(fetchResult.page, 0)
            XCTAssertEqual(fetchResult.items.count, 2)

            let ids = fetchResult.items.map { $0.id }
            // timestamp DESC → now(id2), older(id3)
            XCTAssertEqual(ids, ["2", "3"])
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func test_fetch_withSecondPage_returnsRemainingItems() throws {
        // given
        let now = Date()
        let older = now.addingTimeInterval(-100)
        let oldest = now.addingTimeInterval(-200)

        try insertRecent(id: "1", name: "A", koreanName: "가", type: "CITY", timestamp: oldest)
        try insertRecent(id: "2", name: "B", koreanName: "나", type: "RIVER", timestamp: now)
        try insertRecent(id: "3", name: "C", koreanName: "다", type: "MOUNTAIN", timestamp: older)

        // when: page 1, limit 2 → 세 번째 하나만 남음 (id1)
        let result = sut.fetch(limit: 2, page: 1)

        // then
        switch result {
        case .success(let fetchResult):
            XCTAssertEqual(fetchResult.total, 3)
            XCTAssertEqual(fetchResult.page, 1)
            XCTAssertEqual(fetchResult.items.count, 1)
            XCTAssertEqual(fetchResult.items.first?.id, "1")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - save(_:)

    func test_save_insertsNewEntityAndEmitsDidChanged() throws {
        // given
        let place = Place.mock(id: "p1", name: "Place 1")
        let didChangeExp = expectation(description: "didChanged$ emitted once")

        sut.didChanged$
            .subscribe(onNext: { _ in
                didChangeExp.fulfill()
            })
            .disposed(by: disposeBag)

        // when
        let result = sut.save(place)

        // then
        switch result {
        case .success:
            let entities = try fetchAllEntities()
            XCTAssertEqual(entities.count, 1)
            let entity = entities[0]
            XCTAssertEqual(entity.id, "p1")
            XCTAssertEqual(entity.name, "Place 1")
            // koreanName, type 은 mock 기본값에 따라 달라질 수 있지만 nil 은 아님
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }

        wait(for: [didChangeExp], timeout: 1.0)
    }

    func test_save_updatesExistingEntityTimestampWithoutDuplicating() throws {
        // given: 기존 엔티티 하나
        let oldDate = Date().addingTimeInterval(-100)
        try insertRecent(id: "p1", name: "Old", koreanName: "예전", type: "CITY", timestamp: oldDate)

        let place = Place.mock(id: "p1", name: "New Name")

        // when
        let result = sut.save(place)

        // then
        switch result {
        case .success:
            let entities = try fetchAllEntities()
            XCTAssertEqual(entities.count, 1, "Duplicate should not be created")

            let entity = entities[0]
            XCTAssertEqual(entity.id, "p1")
            XCTAssertEqual(entity.name, "Old") // 이름은 기존 그대로 사용 (service 코드 기준)
            XCTAssertNotNil(entity.timestamp)
            XCTAssertTrue(entity.timestamp! > oldDate, "timestamp should be updated to a newer date")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - delete(id:)

    func test_delete_removesEntityById() throws {
        // given
        try insertRecent(id: "1", name: "A", koreanName: "가", type: "CITY", timestamp: Date())
        try insertRecent(id: "2", name: "B", koreanName: "나", type: "RIVER", timestamp: Date())

        // when
        let result = sut.delete(id: "1")

        // then
        switch result {
        case .success:
            let entities = try fetchAllEntities()
            XCTAssertEqual(entities.count, 1)
            XCTAssertEqual(entities.first?.id, "2")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - clearAll()

    func test_clearAll_deletesAllAndEmitsDidChanged() throws {
        // given
        try insertRecent(id: "1", name: "A", koreanName: "가", type: "CITY", timestamp: Date())
        try insertRecent(id: "2", name: "B", koreanName: "나", type: "RIVER", timestamp: Date())

        let didChangeExp = expectation(description: "didChanged$ emitted on clearAll")

        sut.didChanged$
            .subscribe(onNext: { _ in
                didChangeExp.fulfill()
            })
            .disposed(by: disposeBag)

        // when
        let result = sut.clearAll()

        // then
        wait(for: [didChangeExp], timeout: 1.0)

        switch result {
        case .success:
            let entities = try fetchAllEntities()
            XCTAssertEqual(entities.count, 0)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }
}

