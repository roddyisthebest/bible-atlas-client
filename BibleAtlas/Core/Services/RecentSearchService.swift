//
//  RecentSearchService.swift
//  BibleAtlas
//
//  Created by 배성연 on 7/6/25.
//

import UIKit
import CoreData
import RxSwift
struct RecentSearchItem {
    let id: String
    let name: String
    let type: String
}


enum RecentSearchError: LocalizedError ,Equatable{
    static func == (lhs: RecentSearchError, rhs: RecentSearchError) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown):
            return true

        case let (.fetchFailed(l), .fetchFailed(r)),
             let (.saveFailed(l), .saveFailed(r)),
             let (.deleteFailed(l), .deleteFailed(r)),
             let (.clearFailed(l), .clearFailed(r)):
            let ln = l as NSError
            let rn = r as NSError
            return ln.domain == rn.domain && ln.code == rn.code

        default:
            return false
        }
    }
    
    case fetchFailed(Error)
    case saveFailed(Error)
    case deleteFailed(Error)
    case clearFailed(Error)
    case unknown
    
    var description: String? {
        switch self {
           case .fetchFailed(let error):
               return "최근 검색어를 가져오는 데 실패했어요: \(error.localizedDescription)"
           case .saveFailed(let error):
               return "저장 중 문제가 발생했어요: \(error.localizedDescription)"
           case .deleteFailed(let error):
            return "삭제에 실패했어요. \(error.localizedDescription)"
           case .clearFailed(let error):
               return "전체 삭제에 실패했어요. \(error.localizedDescription)"
           case .unknown:
               return "알 수 없는 오류가 발생했어요."
           }
    }
    
    
}


struct RecentSearchFetchResult {
    let items: [RecentSearchItem]
    let total: Int
    let page:Int
}

protocol RecentSearchServiceProtocol{
    func fetch(limit: Int, page: Int?) -> Result<RecentSearchFetchResult, RecentSearchError>
    func save(_ place:Place) -> Result<Void, RecentSearchError>
    func delete(id: String) -> Result<Void, RecentSearchError>
    func clearAll() -> Result<Void, RecentSearchError>
    
    var didChanged$: Observable<Void> { get }

}





final class RecentSearchService: RecentSearchServiceProtocol{
    private let didChangeSubject$ = PublishSubject<Void>()
    public var didChanged$: Observable<Void> {
        didChangeSubject$.asObservable()
    }
    
    func fetch(limit: Int, page: Int?) -> Result<RecentSearchFetchResult, RecentSearchError> {
        let fetchRequest: NSFetchRequest<RecentSearchEntity> = RecentSearchEntity.fetchRequest()
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        let page = page ?? 0;
        
        fetchRequest.fetchLimit = limit
        fetchRequest.fetchOffset = limit * page

        
        do{
            let total = try context.count(for: RecentSearchEntity.fetchRequest())
            let entities = try context.fetch(fetchRequest)
            let items = entities.map {
                RecentSearchItem(
                    id: $0.id ?? "",
                    name: $0.name ?? "",
                    type: $0.type ?? ""
                )
            }
            
            return .success(RecentSearchFetchResult(items: items, total: total, page: page))
            
        } catch{
            return .failure(.fetchFailed(error))
        }
        
    }
    
    func save(_ place: Place) -> Result<Void, RecentSearchError> {
        
        let fetchRequest: NSFetchRequest<RecentSearchEntity> = RecentSearchEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", place.id)
        
        do {
            if let existing = try context.fetch(fetchRequest).first {
                existing.timestamp = Date()
            } else {
                let entity = RecentSearchEntity(context: context)
                entity.id = place.id
                entity.name = place.name
                entity.type = place.types.first?.name.rawValue ?? ""
                entity.timestamp = Date()
            }
            try context.save()
            didChangeSubject$.onNext(())
            return .success(())

        } catch {
            return .failure(.saveFailed(error))
        }
    }
    
    func delete(id: String) -> Result<Void, RecentSearchError> {
        let fetchRequest: NSFetchRequest<RecentSearchEntity> = RecentSearchEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)

        do {
            let entities = try context.fetch(fetchRequest)
            entities.forEach { context.delete($0) }
            return .success(())
        } catch {
            return .failure(.deleteFailed(error))
        }
    }
    
    func clearAll() -> Result<Void, RecentSearchError> {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = RecentSearchEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do{
            try context.execute(deleteRequest)
            try context.save()
            didChangeSubject$.onNext(())
            return .success(())
        }catch{
            return .failure(.clearFailed(error))
        }
        
    }
    
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
          self.context = context
    }
    

    
}
