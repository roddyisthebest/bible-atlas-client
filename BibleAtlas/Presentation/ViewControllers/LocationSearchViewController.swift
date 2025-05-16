//
//  LocationSearchViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 3/7/25.
//

struct BiblicalLocation {
    let name: String
    let latitude: Double
    let longitude: Double
}

import UIKit
import MapKit
import SnapKit
final class LocationSearchViewController: UIViewController {
        
    private var initialCoordinate: CLLocationCoordinate2D?
    private let bottomSheetHeightRatio = 0.65;

    
    let biblicalLocations: [BiblicalLocation] = [
        BiblicalLocation(name: "예루살렘", latitude: 31.7683, longitude: 35.2137),
        BiblicalLocation(name: "베들레헴", latitude: 31.7054, longitude: 35.2024),
        BiblicalLocation(name: "갈릴리", latitude: 32.7959, longitude: 35.5309),
        BiblicalLocation(name: "나사렛", latitude: 32.6996, longitude: 35.3035),
        BiblicalLocation(name: "여리고", latitude: 31.8700, longitude: 35.4430),
        BiblicalLocation(name: "가버나움", latitude: 32.8803, longitude: 35.5733),
        BiblicalLocation(name: "사마리아", latitude: 32.2226, longitude: 35.2618),
        BiblicalLocation(name: "안디옥", latitude: 36.2021, longitude: 36.1600),
        BiblicalLocation(name: "고린도", latitude: 37.9386, longitude: 22.9322),
        BiblicalLocation(name: "에베소", latitude: 37.9499, longitude: 27.3685),
        BiblicalLocation(name: "서울", latitude: 37.5665, longitude: 126.9780),
        BiblicalLocation(name: "도쿄", latitude: 35.6895, longitude: 139.6917)


    ]
    
    
    private lazy var mapView:MKMapView = {
        let mv = MKMapView();
        mv.delegate = self;
        view.addSubview(mv);
        mv.addSubview(searchBarButton)
        return mv;
    }()
    
        
    private let searchBarButton: UIButton = {
        var config = UIButton.Configuration.plain()
        

        let imageConfig = UIImage.SymbolConfiguration(weight: .bold)
        config.preferredSymbolConfigurationForImage = imageConfig
        
        let button = UIButton(configuration: config)
        
        button.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        button.tintColor = .primaryViolet
        
        
        let title = "여기서 검색"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16), // Bold 폰트
            .foregroundColor: UIColor.white // 글씨 색상
        ]
        let attributedTitle = NSAttributedString(string: title, attributes: attributes)
        button.setAttributedTitle(attributedTitle, for: .normal)
        
        button.backgroundColor = .thirdGray
        button.layer.cornerRadius = 25

        button.configuration?.imagePadding = 8
        button.configuration?.imagePlacement = .leading
        
        button.contentHorizontalAlignment = .leading

        button.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)

        button.addTarget(self, action: #selector(searchBarButtonTapped), for: .touchUpInside)

        return button
    }()

    
    init(coordinate: CLLocationCoordinate2D?) {
        super.init(nibName: nil, bundle: nil)
        
        print("✅ LocationSearchViewController init called with coordinate: \(String(describing: coordinate))")

        guard let coordinate = coordinate else {
            print("❌ Error: coordinate is nil")
            return
        }

        initialCoordinate = coordinate
    }

    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupConstraints()
        addCustomPins();
        
        guard let initialCoordinate = initialCoordinate else {
            return;
        }
        
        moveToNewLocation(coordinate: initialCoordinate)
        // Do any additional setup after loading the view.
    }

    
    private func setupConstraints(){
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview();
        }
        
        searchBarButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
            make.top.equalTo(view.safeAreaLayoutGuide);
            make.height.equalTo(50);
            
        }
    }
    
    
    private func addCustomPins() {
        for location in biblicalLocations {
            let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            let annotation = CustomAnnotation(coordinate: coordinate, title: nil, subtitle: nil)
            mapView.addAnnotation(annotation)
        }

    }
    
    @objc private func searchBarButtonTapped(){
        let searchVC = SearchViewController();
        searchVC.modalTransitionStyle = .flipHorizontal;
        searchVC.modalPresentationStyle = .fullScreen
        present(searchVC,animated: false)
    }
    
    private func moveToNewLocation(coordinate:CLLocationCoordinate2D){
        guard let filteredLocation = biblicalLocations.filter({ $0.latitude == coordinate.latitude}).first else {
            return;
        };
        
        centerMapOnLocation(coordinate);
        showBottomSheet(name:filteredLocation.name)
    }
    
    
    @objc private func showBottomSheet(name:String?) {
        let bottomSheetVC = LocationDetailBottomSheet()
        
        if let sheet = bottomSheetVC.sheetPresentationController {
            
            let customDetent = UISheetPresentationController.Detent.custom { context in
                return UIScreen.main.bounds.height * self.bottomSheetHeightRatio
            }
            
            sheet.detents = [customDetent] // 높이 조절 가능 (중간, 전체 화면)
            sheet.prefersGrabberVisible = true // 위쪽 핸들 표시
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true // 스크롤 시 확장 가능
            
        }
        
        // TODO: background에서 실행될수도 있음 why?
        DispatchQueue.main.async {
            self.present(bottomSheetVC, animated: true)
        }
    }
    
    
    private func centerMapOnLocation(_ location: CLLocationCoordinate2D) {
        let remainingRatio = 1 - bottomSheetHeightRatio
        let halfRemainingRatio = remainingRatio / 2
        
        let screenHeight = UIScreen.main.bounds.height
        let yOffset = screenHeight * halfRemainingRatio
        let adjustedLatitude = location.latitude - (yOffset * 0.0045);
        
        let adjustedLocation = CLLocationCoordinate2D(
               latitude: adjustedLatitude,
               longitude: location.longitude
        )
        let region = MKCoordinateRegion(center: adjustedLocation, latitudinalMeters: 100000, longitudinalMeters: 100000);
        self.mapView.setRegion(region, animated: true)

    }
}




extension LocationSearchViewController:MKMapViewDelegate {
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation as? CustomAnnotation else { return }
        moveToNewLocation(coordinate: annotation.coordinate);
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }

        let identifier = "customPin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true // ✅ 핀 선택 시 타이틀 표시
        } else {
            annotationView?.annotation = annotation
        }


        let image = UIImage(systemName: "location.fill")?.withRenderingMode(.alwaysTemplate)
        annotationView?.image = image
        annotationView?.tintColor = .systemRed // ✅ 핀 색상 변경 가능

        return annotationView
    }
}



class CustomAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?

    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}
