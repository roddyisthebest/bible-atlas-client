//
//  LocationPickerViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 3/8/25.
//

import UIKit
import MapKit

final class LocationPickerViewController: UIViewController {
    
    
    private var isStandard = true;
    
    private lazy var mapView:MKMapView = {
        let mv = MKMapView();
        mv.delegate = self;
        view.addSubview(mv);
        mv.addSubview(mainHeaderContainer)
        mv.addSubview(buttonsContainer)
        return mv;
    }()
    
    
    private lazy var mainHeaderContainer = {
        let v = UIView();
        v.addSubview(mainHeaderView)
        v.addSubview(mapTypeButton)
        return v;
    }();
    
    private lazy var mainHeaderView = {
        let v = UIView();
        v.backgroundColor = .thirdGray;
        v.layer.cornerRadius = 10;
        v.layer.masksToBounds = true;
        v.addSubview(handRayIcon);
        v.addSubview(mainHeaderLabel)
        return v;
    }()
    
    
    private let mapTypeButton = {
        var config = UIButton.Configuration.plain()

        let imageConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)

        config.preferredSymbolConfigurationForImage = imageConfig
        
        let button = UIButton(configuration: config)
        
        let image = UIImage(systemName: "globe.americas.fill")
        button.tintColor = .lightestGray;
        button.setImage(image,for:.normal);
        button.backgroundColor = .thirdGray;
        button.layer.cornerRadius = 10;
        button.layer.masksToBounds = true;
        button.addTarget(self, action: #selector(mapTypeButtonTapped), for: .touchUpInside)
        return button;
        
    }();
    
    private let handRayIcon = {
        let image = UIImage(systemName: "hand.tap.fill");
        let iv = UIImageView(image:image);
        iv.contentMode = .scaleAspectFill
        iv.tintColor = .primaryViolet;
        
        return iv;
    }()
    
    private let mainHeaderLabel = {
        let label = UILabel();
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = .white;
        label.text = "새롭게 등록할 지역을 선택해주세요."
        return label;
    }()
    
    private lazy var buttonsContainer = {
        let v = UIView();
        v.addSubview(locationSelectButton)
        v.addSubview(keywordSearchButton)
        return v;
    }();
    

    
    
    private let locationSelectButton = {

        var config = UIButton.Configuration.plain()

        let imageConfig = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)

        config.preferredSymbolConfigurationForImage = imageConfig
        
        let button = UIButton(configuration: config)

        button.setImage(UIImage(systemName: "location.fill"), for: .normal)
        button.tintColor = .white;
        button.setTitleColor(.white, for: .normal)
        
        let title = "위도 경도 선택"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.white,
        ]
        let attributedTitle = NSAttributedString(string: title, attributes: attributes)

        button.setAttributedTitle(attributedTitle, for: .normal)
        button.backgroundColor = .thirdGray;
        button.layer.cornerRadius = 8;
        
        
        button.configuration?.imagePadding = 4
        button.configuration?.imagePlacement = .leading
        
        button.addTarget(self, action: #selector(locationSelectButtontapped), for: .touchUpInside)
        

        
        return button;
    }()
    
    
    
    private let keywordSearchButton = {

        var config = UIButton.Configuration.plain()

        let imageConfig = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)

        config.preferredSymbolConfigurationForImage = imageConfig
        
        let button = UIButton(configuration: config)

        button.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        
        button.tintColor = .white;
        button.setTitleColor(.white, for: .normal)
        
        let title = "키워드 검색"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.white
        ]
        let attributedTitle = NSAttributedString(string: title, attributes: attributes)

        button.setAttributedTitle(attributedTitle, for: .normal)
        button.backgroundColor = .thirdGray;
        button.layer.cornerRadius = 8;
        
        button.configuration?.imagePadding = 4
        button.configuration?.imagePlacement = .leading
        
        
        return button;
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addTapGestureRecognizer();
        setupConstraints();
        // Do any additional setup after loading the view.
    }
    
    
    @objc private func mapTypeButtonTapped(){
        isStandard = !isStandard
        
        if(!isStandard){
            let globeImage = UIImage(systemName: "globe.americas.fill")
            mapTypeButton.setImage(globeImage, for: .normal)
            mapView.mapType = .hybridFlyover

        }
        else{
            let mapImage = UIImage(systemName: "map.fill")
            mapTypeButton.setImage(mapImage, for: .normal)
            mapView.mapType = .standard
        }
        
        
        
        
    }
    
    private func addTapGestureRecognizer(){
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
    }

    
    private func centerMapOnLocation(_ location: CLLocationCoordinate2D) {
        
        let region = MKCoordinateRegion(center: location, latitudinalMeters: 100000, longitudinalMeters: 100000)
        mapView.setRegion(region, animated: true)
    }
    
    private func addAnnotation(_ location:CLLocationCoordinate2D){
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = location

        annotation.title = "위도: \(location.latitude), 경도: \(location.longitude)"
      
        

        mapView.addAnnotation(annotation)
    }
    
    @objc private func locationSelectButtontapped(){
        let vc = PlaceSearchViewController();
        vc.modalPresentationStyle = .fullScreen
        present(vc,animated: false)
    }
    
    @objc private func handleMapTap(_ sender: UITapGestureRecognizer){
        let locationInView = sender.location(in: mapView)
        let coordinate = mapView.convert(locationInView, toCoordinateFrom: mapView);
        
        addAnnotation(coordinate)
        centerMapOnLocation(coordinate)
        
        showBottomSheet();

    }
    
    private func setupConstraints(){
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview();
        }
        
        
        mainHeaderContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
            make.top.equalTo(view.safeAreaLayoutGuide);
            make.height.equalTo(50);
        }
        
        mainHeaderView.snp.makeConstraints { make in
            make.leading.bottom.top.equalToSuperview();

        }
        
        mapTypeButton.snp.makeConstraints { make in
            make.leading.equalTo(mainHeaderView.snp.trailing).offset(10);
            make.top.bottom.equalToSuperview();
            make.width.equalTo(50);
        }
        
        handRayIcon.snp.makeConstraints { make in
            make.centerY.equalToSuperview();
            make.leading.equalToSuperview().offset(16);
            make.height.width.equalTo(20)
        }
        
        mainHeaderLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview();
            make.trailing.equalToSuperview().inset(16);
            make.leading.equalTo(handRayIcon.snp.trailing).offset(16)
        }
        
        
        buttonsContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
            
            make.top.equalTo(mainHeaderContainer.snp.bottom).offset(10);
        }
        
        locationSelectButton.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview();
        
        }
        
        keywordSearchButton.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview();
            make.leading.equalTo(locationSelectButton.snp.trailing).offset(10)
        }
    }
 
    private func showBottomSheet(){
        let bottomSheetVC = LocationComfirmBottomSheet();
        
        if let sheet = bottomSheetVC.sheetPresentationController {
            
            let customDetent = UISheetPresentationController.Detent.custom { context in
                return UIScreen.main.bounds.height * 0.3
            }
            
            sheet.detents = [customDetent] // 높이 조절 가능 (중간, 전체 화면)
            sheet.prefersGrabberVisible = true // 위쪽 핸들 표시
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true // 스크롤 시 확장 가능
        }
        
        
        present(bottomSheetVC, animated: true)
        
    }

}


extension LocationPickerViewController:MKMapViewDelegate {
    

    
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }

        let identifier = "customPin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        } else {
            annotationView?.annotation = annotation
        }

        // ✅ 핀 색상 변경
        annotationView?.markerTintColor = .black
        annotationView?.glyphImage = UIImage(systemName: "mappin.fill") // SF Symbol 사용

 

        return annotationView
    }

}

