//
//  MKMapRect.swift
//  BibleAtlas
//
//  Created by 배성연 on 7/29/25.
//

import MapKit


extension MKMapRect {
    init(for region: MKCoordinateRegion) {
        let topLeft = CLLocationCoordinate2D(
            latitude: region.center.latitude + (region.span.latitudeDelta / 2),
            longitude: region.center.longitude - (region.span.longitudeDelta / 2)
        )
        let bottomRight = CLLocationCoordinate2D(
            latitude: region.center.latitude - (region.span.latitudeDelta / 2),
            longitude: region.center.longitude + (region.span.longitudeDelta / 2)
        )

        let a = MKMapPoint(topLeft)
        let b = MKMapPoint(bottomRight)

        self = MKMapRect(
            origin: MKMapPoint(x: min(a.x, b.x), y: min(a.y, b.y)),
            size: MKMapSize(width: abs(a.x - b.x), height: abs(a.y - b.y))
        )
    }
    
    
    /// rect를 anchor(MKMapPoint) 기준으로 배율(scale)만큼 스케일
        func scaled(around anchor: MKMapPoint, by scale: Double) -> MKMapRect {
            precondition(scale > 0)
            let dx = origin.x - anchor.x
            let dy = origin.y - anchor.y
            let newOrigin = MKMapPoint(x: anchor.x + dx * scale,
                                       y: anchor.y + dy * scale)
            return MKMapRect(x: newOrigin.x,
                             y: newOrigin.y,
                             width: size.width * scale,
                             height: size.height * scale)
        }
}
