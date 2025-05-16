//
//  LocationPicker.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/26/25.
//

import UIKit
import MapKit
final class LocationPicker: UIView {

  
    private lazy var containerStackView:UIStackView = {
        let uv = UIStackView();
        uv.axis = .horizontal;
        uv.distribution = .equalSpacing;
        return uv;
    }()
    
    private var oldMapView: MKMapView!
    private var newMapView: MKMapView?
    
    
    private let newLocationButton:UIButton = {
        let button = UIButton();
        button.backgroundColor = .lightestGray
        return button;
    }()
    
    
    
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        setupMapView()
    }
    
    private func setupMapView(){
        oldMapView = MKMapView(frame:bounds);
        oldMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight];
        addSubview(oldMapView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
