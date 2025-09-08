//
//  AppEnvironment.swift
//  BibleAtlas
//
//  Created by 배성연 on 9/8/25.
//

import Foundation

struct AppEnvironment {
    let baseURL: URL
    let geoJSONURL: URL

    init(baseURLString: String, geoJSONURLString: String) {
        self.baseURL = URL(string: baseURLString)!
        self.geoJSONURL = URL(string: geoJSONURLString)!
    }
}
