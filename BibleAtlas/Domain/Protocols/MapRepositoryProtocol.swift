//
//  GeoJsonRepositoryProtocol.swift
//  BibleAtlas
//
//  Created by 배성연 on 6/9/25.
//

import Foundation
import MapKit

protocol MapRepositoryProtocol {
    func getGeoJson(placeId:String) async -> Result<[MKGeoJSONFeature], NetworkError>
}
