//
//  RecentSearchEntity+CoreDataProperties.swift
//  BibleAtlas
//
//  Created by 배성연 on 7/6/25.
//
//

import Foundation
import CoreData


extension RecentSearchEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RecentSearchEntity> {
        return NSFetchRequest<RecentSearchEntity>(entityName: "RecentSearchEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var type: NSObject?

}

extension RecentSearchEntity : Identifiable {

}
