//
//  DiffCode.swift
//  BibleAtlas
//
//  Created by 배성연 on 3/3/25.
//

import Foundation


enum Status {
    case add
    case delete
    case notChange
}


struct DiffCode:Equatable{
    var status:Status
    var content:String
    var hilightedContent:String?
    var oldLineNumber:Int
    var newLineNumber:Int
}
