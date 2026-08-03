import XCTest
import CoreData
@testable import BibleAtlas

final class CoreDataChatHistoryStoreTests: XCTestCase {
    private var container: NSPersistentContainer!
    private var sut: CoreDataChatHistoryStore!

    override func setUp() {
        super.setUp()
        container = NSPersistentContainer(name: "BibleAtlas")
        let desc = NSPersistentStoreDescription()
        desc.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [desc]
        let exp = expectation(description: "load stores")
        container.loadPersistentStores { _, error in
            XCTAssertNil(error)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
        sut = CoreDataChatHistoryStore(context: container.viewContext)
    }

    override func tearDown() {
        sut = nil
        container = nil
        super.tearDown()
    }

    // MARK: - summary

    func test_summary_persistsAndReloads() {
        sut.updateContext(summary: "s1", messages: [])
        XCTAssertEqual(sut.loadSummary(), "s1")
        sut.updateContext(summary: nil, messages: [])
        XCTAssertNil(sut.loadSummary())
    }

    // MARK: - messages

    func test_messages_replaceOnEachUpdate() {
        sut.updateContext(summary: nil, messages: [
            .init(role: .user, content: "q1"),
            .init(role: .assistant, content: "a1"),
        ])
        XCTAssertEqual(sut.loadMessages().count, 2)
        sut.updateContext(summary: nil, messages: [.init(role: .user, content: "q2")])
        XCTAssertEqual(sut.loadMessages().count, 1)
        XCTAssertEqual(sut.loadMessages().first?.content, "q2")
    }

    // MARK: - bubbles append + load

    func test_appendBubble_persistsAllKinds() {
        let user = ChatBubble(kind: .user, text: "질문")
        let assistant = ChatBubble(kind: .assistant(placeIdMap: ["place": ["a1"]], recommendedQuestions: ["q1"]), text: "답변")
        let error = ChatBubble(kind: .error("오류"), text: "오류")
        sut.appendBubble(user)
        sut.appendBubble(assistant)
        sut.appendBubble(error)

        let page = sut.loadBubbles(beforeOrder: nil, limit: 10)
        XCTAssertEqual(page.bubbles.count, 3)
        XCTAssertFalse(page.hasMore)
        XCTAssertNil(page.nextCursor)
        XCTAssertEqual(page.bubbles[0].text, "질문")
        if case .assistant(let map, let qs) = page.bubbles[1].kind {
            XCTAssertEqual(map["place"], ["a1"])
            XCTAssertEqual(qs, ["q1"])
        } else { XCTFail("expected assistant kind") }
        if case .error(let m) = page.bubbles[2].kind { XCTAssertEqual(m, "오류") }
        else { XCTFail("expected error kind") }
    }

    func test_pendingBubble_isNotPersisted() {
        let pending = ChatBubble(kind: .pending(label: "..."), text: "...")
        sut.appendBubble(pending)
        let page = sut.loadBubbles(beforeOrder: nil, limit: 10)
        XCTAssertEqual(page.bubbles.count, 0)
    }

    // MARK: - pagination

    func test_loadBubbles_returnsMostRecentFirstPage_andReportsHasMore() {
        for i in 0..<25 {
            sut.appendBubble(ChatBubble(kind: .user, text: "b\(i)"))
        }
        let first = sut.loadBubbles(beforeOrder: nil, limit: 20)
        XCTAssertEqual(first.bubbles.count, 20)
        XCTAssertEqual(first.bubbles.first?.text, "b5")
        XCTAssertEqual(first.bubbles.last?.text, "b24")
        XCTAssertTrue(first.hasMore)
        XCTAssertNotNil(first.nextCursor)

        let older = sut.loadBubbles(beforeOrder: first.nextCursor, limit: 20)
        XCTAssertEqual(older.bubbles.count, 5)
        XCTAssertEqual(older.bubbles.first?.text, "b0")
        XCTAssertEqual(older.bubbles.last?.text, "b4")
        XCTAssertFalse(older.hasMore)
        XCTAssertNil(older.nextCursor)
    }

    // MARK: - clear

    func test_clear_removesAll() {
        sut.appendBubble(ChatBubble(kind: .user, text: "x"))
        sut.updateContext(summary: "s", messages: [.init(role: .user, content: "x")])
        sut.clear()
        XCTAssertEqual(sut.loadBubbles(beforeOrder: nil, limit: 10).bubbles.count, 0)
        XCTAssertEqual(sut.loadMessages().count, 0)
        XCTAssertNil(sut.loadSummary())
    }
}
