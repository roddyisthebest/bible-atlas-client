//
//  Constants.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/26/25.
//

import Foundation

final class Constants {
    static let shared = Constants()

    private init() {}

    let url: String = "http://192.168.123.107:4343"
    let geoJsonUrl: String = "https://a.openbible.info/geo/data"
}
