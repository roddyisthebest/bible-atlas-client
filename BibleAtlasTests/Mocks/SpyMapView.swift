//
//  SpyMapView.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/21/25.
//

import Foundation
import MapKit
final class SpyMapView: MKMapView {
    struct Call {
        let rect: MKMapRect
        let padding: UIEdgeInsets
        let animated: Bool
    }
    private(set) var setVisibleCalls: [Call] = []

    override func setVisibleMapRect(_ mapRect: MKMapRect,
                                    edgePadding insets: UIEdgeInsets,
                                    animated animate: Bool) {
        setVisibleCalls.append(.init(rect: mapRect, padding: insets, animated: animate))
        super.setVisibleMapRect(mapRect, edgePadding: insets, animated: animate)
    }
}
