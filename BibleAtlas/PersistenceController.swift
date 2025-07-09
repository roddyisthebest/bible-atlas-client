//
//  PersistenceController.swift
//  BibleAtlas
//
//  Created by 배성연 on 7/6/25.
//

import Foundation
import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "BibleAtlas") // .xcdatamodeld 이름
        container.loadPersistentStores { (desc, error) in
            if let error = error {
                fatalError("❌ CoreData 초기화 실패: \(error)")
            }
        }
    }
}
