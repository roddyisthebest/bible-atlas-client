//
//  Report.swift
//  BibleAtlas
//
//  Created by 배성연 on 7/23/25.
//

import Foundation


enum PlaceReportType:Int {
    case spam
    case inappropriate
    case hateSpeech
    case falseInfomation
    case personalInfomation
    case etc
}

struct PlaceReport {
    var type: PlaceReportType
    var reason: String?
    var place: Place
    var creator: User
    
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date

    var version: Int
    var id: Int
}
