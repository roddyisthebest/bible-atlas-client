//
//  Env.swift
//  BibleAtlas
//
//  Created by 배성연 on 10/8/25.
//

import Foundation

enum Env {
    static var name: String {
        Bundle.main.object(forInfoDictionaryKey: "PRODUCT_NAME") as? String ?? "debug"
    }
    static var apiBaseURL: String {
        Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String ?? ""
    }
}
