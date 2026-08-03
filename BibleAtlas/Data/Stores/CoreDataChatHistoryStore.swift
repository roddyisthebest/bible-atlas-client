import Foundation
import CoreData
import os.log

final class CoreDataChatHistoryStore: ChatHistoryStoreProtocol {
    private let context: NSManagedObjectContext
    private let log = OSLog(subsystem: "com.bibleatlas.chat", category: "history-store")

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Session summary

    func loadSummary() -> String? {
        sessionEntity()?.summary
    }

    // MARK: - Messages

    func loadMessages() -> [ChatMessage] {
        let req: NSFetchRequest<ChatMessageEntity> = ChatMessageEntity.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        do {
            let rows = try context.fetch(req)
            return rows.compactMap { row in
                guard let roleRaw = row.roleRaw, let role = ChatRole(rawValue: roleRaw),
                      let content = row.content else { return nil }
                return ChatMessage(role: role, content: content)
            }
        } catch {
            os_log("loadMessages failed: %{public}@", log: log, type: .error, "\(error)")
            return []
        }
    }

    func updateContext(summary: String?, messages: [ChatMessage]) {
        let session = sessionEntity() ?? ChatSessionEntity(context: context)
        session.summary = summary

        // messages: fetch + context.delete + insert
        // (NSBatchDeleteRequest는 context를 우회해 stale object를 남기므로 회피)
        let req: NSFetchRequest<ChatMessageEntity> = ChatMessageEntity.fetchRequest()
        do {
            try context.fetch(req).forEach { context.delete($0) }
        } catch {
            os_log("fetch messages for delete failed: %{public}@", log: log, type: .error, "\(error)")
        }
        for (idx, msg) in messages.enumerated() {
            let entity = ChatMessageEntity(context: context)
            entity.roleRaw = msg.role.rawValue
            entity.content = msg.content
            entity.order = Int64(idx)
        }
        saveContext(op: "updateContext")
    }

    // MARK: - Bubbles

    func loadBubbles(beforeOrder: Int64?, limit: Int) -> ChatBubblePage {
        let req: NSFetchRequest<ChatBubbleEntity> = ChatBubbleEntity.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "order", ascending: false)]
        req.fetchLimit = limit + 1
        if let cursor = beforeOrder {
            req.predicate = NSPredicate(format: "order < %lld", cursor)
        }
        do {
            let rows = try context.fetch(req)
            let hasMore = rows.count > limit
            let taken = Array(rows.prefix(limit))
            // taken 은 order DESC 순. reverse 하면 asc.
            let ascEntities = Array(taken.reversed())
            let bubbles = ascEntities.compactMap { mapBubble($0) }
            let nextCursor: Int64? = hasMore ? ascEntities.first?.order : nil
            return ChatBubblePage(bubbles: bubbles, hasMore: hasMore, nextCursor: nextCursor)
        } catch {
            os_log("loadBubbles failed: %{public}@", log: log, type: .error, "\(error)")
            return ChatBubblePage(bubbles: [], hasMore: false, nextCursor: nil)
        }
    }

    func appendBubble(_ bubble: ChatBubble) {
        // pending 은 저장 안 함 (entity 생성 전 조기 반환 — rollback은 무관한 in-flight 변경까지 지우므로 회피)
        if case .pending = bubble.kind { return }

        let entity = ChatBubbleEntity(context: context)
        entity.id = bubble.id
        entity.text = bubble.text
        entity.order = nextOrder()
        switch bubble.kind {
        case .user:
            entity.kindRaw = "user"
        case .assistant(let map, let questions):
            entity.kindRaw = "assistant"
            entity.placeIdMapJson = encodeJson(map)
            entity.recommendedQuestionsJson = encodeJson(questions)
        case .error:
            entity.kindRaw = "error"
        case .pending:
            return   // 위 조기 반환으로 unreachable
        }
        saveContext(op: "appendBubble")
    }

    func clear() {
        // fetch + context.delete 로 context in-memory 상태와 동기화 유지
        do {
            try context.fetch(ChatBubbleEntity.fetchRequest()).forEach { context.delete($0) }
            try context.fetch(ChatMessageEntity.fetchRequest()).forEach { context.delete($0) }
            try context.fetch(ChatSessionEntity.fetchRequest()).forEach { context.delete($0) }
        } catch {
            os_log("clear failed: %{public}@", log: log, type: .error, "\(error)")
        }
        saveContext(op: "clear")
    }

    // MARK: - Helpers

    private func sessionEntity() -> ChatSessionEntity? {
        let req: NSFetchRequest<ChatSessionEntity> = ChatSessionEntity.fetchRequest()
        req.fetchLimit = 1
        return (try? context.fetch(req))?.first
    }

    private func nextOrder() -> Int64 {
        let req: NSFetchRequest<ChatBubbleEntity> = ChatBubbleEntity.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "order", ascending: false)]
        req.fetchLimit = 1
        if let last = (try? context.fetch(req))?.first {
            return last.order + 1
        }
        return 0
    }

    private func mapBubble(_ entity: ChatBubbleEntity) -> ChatBubble? {
        guard let id = entity.id, let kindRaw = entity.kindRaw, let text = entity.text else { return nil }
        let kind: ChatBubbleKind
        switch kindRaw {
        case "user":
            kind = .user
        case "assistant":
            let map: [String: [String]] = decodeJson(entity.placeIdMapJson) ?? [:]
            let questions: [String] = decodeJson(entity.recommendedQuestionsJson) ?? []
            kind = .assistant(placeIdMap: map, recommendedQuestions: questions)
        case "error":
            kind = .error(text)
        default:
            return nil
        }
        return ChatBubble(id: id, kind: kind, text: text)
    }

    private func encodeJson<T: Encodable>(_ value: T) -> String? {
        do {
            let data = try JSONEncoder().encode(value)
            return String(data: data, encoding: .utf8)
        } catch {
            os_log("encode json failed: %{public}@", log: log, type: .error, "\(error)")
            return nil
        }
    }

    private func decodeJson<T: Decodable>(_ raw: String?) -> T? {
        guard let raw, let data = raw.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func saveContext(op: String) {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            os_log("save failed [%{public}@]: %{public}@", log: log, type: .error, op, "\(error)")
            context.rollback()
        }
    }
}
