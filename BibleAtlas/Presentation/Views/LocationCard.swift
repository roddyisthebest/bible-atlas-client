//
//  LocationCard.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/24/25.
//

import UIKit
import MapKit

class LocationCard: UIView {
    private var mapView: MKMapView!
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .thirdGray
        
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        return view
    }()
    
    
    private lazy var stackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [titleLabel, contentLabel]);
        sv.axis = .vertical;
        sv.spacing = 8;
        sv.alignment = .fill
        sv.distribution = .fill
        return sv;
    }()
    
    private let titleLabel:UILabel = {
        let label = UILabel();
        label.text = "아주가라너아주가아주가라너아주가아주가라너아주가아주가라너아주가"
        label.font = .boldSystemFont(ofSize: 17)
        label.textColor = .white
        label.numberOfLines = 1;
        label.lineBreakMode = .byTruncatingTail
        return label;
    }()
    
    private let contentLabel:UILabel = {
        let label = UILabel();
        label.text = "아주가라너아주가 아주가라너아주가아주가 라너아주가아주가라너아주가아주가라너아주 가아주가라너아주가아주가라너아주가아주가라너아주가아주가라너아주가아주가라너아주가"
        label.numberOfLines = 3;
        label.lineBreakMode = .byTruncatingTail
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        return label;
    }()
    
    
    init(title: String, description: String) {
        super.init(frame: .zero)
        setupMapView()
        setupUI();
        setupConstraints();

    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(){
        addSubview(containerView)
        containerView.addSubview(stackView);
    }
    
    
    private func setupMapView(){
        mapView = MKMapView(frame:bounds);
        mapView.layer.cornerRadius = 8;
        mapView.layer.masksToBounds = true;
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight];
        containerView.addSubview(mapView)
        centerMapOnLocation(latitude: 37.7749, longitude: -122.4194)
        addAnnotation(latitude: 37.7749, longitude: -122.4194, title: "샌프란시스코", subtitle: "골든 게이트 브리지 근처")
    }
    
    
    private func setupConstraints(){
    
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.greaterThanOrEqualTo(100)
        }
        
        mapView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().inset(10)
            make.width.equalTo(mapView.snp.height)
        }
        
        stackView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(10);
            make.top.equalToSuperview().offset(10);
            make.bottom.equalToSuperview().inset(10)
            make.leading.equalTo(mapView.snp.trailing).offset(10)
        }
        
    
    }
    
    private func centerMapOnLocation(latitude: CLLocationDegrees, longitude: CLLocationDegrees, regionRadius: CLLocationDistance = 1000) {
          let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
          let coordinateRegion = MKCoordinateRegion(
              center: location,
              latitudinalMeters: regionRadius,
              longitudinalMeters: regionRadius
          )
          mapView.setRegion(coordinateRegion, animated: true)
    }
    
        
    private func addAnnotation(latitude: CLLocationDegrees, longitude: CLLocationDegrees, title: String, subtitle: String?) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        annotation.title = title
        annotation.subtitle = subtitle
        mapView.addAnnotation(annotation)
    }
    
    
    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
