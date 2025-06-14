//
//  NotificationName.swift
//  BibleAtlas
//
//  Created by 배성연 on 6/5/25.
//

import Foundation

extension Notification.Name {
    static let refetchRequired = Notification.Name("refetchRequired")
    static let fetchGeoJsonRequired = Notification.Name("fetchGeoJsonRequired")
    static let resetGeoJson = Notification.Name("resetGeoJson")
}
