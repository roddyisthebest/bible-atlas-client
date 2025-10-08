//
//  GeoScene.swift
//  BibleAtlas
//
//  Created by 배성연 on 9/20/25.
//

import Foundation
import CoreLocation

public enum GeoShape {
    case point(id: String?, coord: CLLocationCoordinate2D)
    case polyline(id: String?, coords: [CLLocationCoordinate2D])
    case polygon(id: String?, rings: [[CLLocationCoordinate2D]])
}

public struct GeoScene {
    public let shapes: [GeoShape]
    public init(shapes: [GeoShape]) { self.shapes = shapes }
}
