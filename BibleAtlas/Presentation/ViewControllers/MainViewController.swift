//
//  MainViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/19/25.
//

import UIKit
import MapKit
import RxSwift
import RxRelay


final class MainViewController: UIViewController, Presentable  {

    private var mainViewModel:MainViewModelProtocol?
    private let loadingView = LoadingView();

    private var navigator: BottomSheetNavigator;
    
    private let disposeBag = DisposeBag();
    
    private let viewLoaded$ = PublishRelay<Void>()
    
    
    private var selectedPlaceId:String? = nil;
    
    private let placeAnnotationTapped$ = PublishRelay<String>();
    
    private let isPainting$ = BehaviorRelay<Bool>(value: false);

    
    private let mapView = {
        let mv = MKMapView();
        return mv;
    }()
    
    private func setupUI(){
        view.addSubview(mapView);
        view.addSubview(loadingView)
    }
    
    private func setupConstaints(){
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview();
        }
        
        loadingView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(view.bounds.height * 0.25)
        }

    }
    
            
    init(navigator:BottomSheetNavigator, vm:MainViewModelProtocol?) {
        self.navigator = navigator
        self.mainViewModel = vm;
        super.init(nibName: nil, bundle: nil)
        mapView.delegate = self  // ✅ 여기 추가

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI();
        setupConstaints();
        bindViewModel();
        bindObservable();
        setFirstRegion();
        viewLoaded$.accept(Void())

    }
    
    func present(vc: ViewController, animated: Bool) {
        super.present(vc, animated: animated)
    }

    func dismiss(animated: Bool) {
        super.dismiss(animated: animated)
    }
    
    private func bindViewModel(){
        let output = mainViewModel?.transform(input: MainViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), placeAnnotationTapped$: placeAnnotationTapped$.asObservable()))
        
        output?.placesWithRepresentativePoint$
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: {[weak self] places in
                self?.renderPlaces(places: places)
            })
            .disposed(by:disposeBag)
        
        
        output?.selectedPlaceId$
            .subscribe(onNext: {[weak self] selectedPlaceId in
                self?.selectedPlaceId = selectedPlaceId;
            })
            .disposed(by: disposeBag)
        
        output?.isLoading$
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: {[weak self] isLoading in
                if(isLoading){
                    self?.mapView.isUserInteractionEnabled = false
                    self?.loadingView.start();
                }
                else{
                    
                    self?.mapView.isUserInteractionEnabled = true;
                    self?.loadingView.stop()

                }
                
            })
            .disposed(by: disposeBag)
        
        output?.geoJsonRender$
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] geoJson in
                self?.renderGeoJson(features: geoJson)

            })
            .disposed(by: disposeBag)
        
        
        output?.resetMapView$
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self]  in
                self?.clearMapView();
            })
            .disposed(by: disposeBag)
    }
    
    private func bindObservable(){
        isPainting$.asObservable()
            .subscribe(onNext: {[weak self] isPainting in
                if(isPainting){
                    self?.mapView.isUserInteractionEnabled = false
                    self?.loadingView.start();
                }
                else{
                    
                    self?.mapView.isUserInteractionEnabled = true;
                    self?.loadingView.stop()

                }
        }).disposed(by: disposeBag)
    }
    
    private func clearMapView(){
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
    }
    
    private func setFirstRegion() {
        let initialCenter = CLLocationCoordinate2D(latitude: 31.7683, longitude: 35.2137)
        let initialSpan = MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
        
        let shiftRatio: CLLocationDegrees = 0.5  // 위로 50% 이동
        let shiftedLatitude = initialCenter.latitude - initialSpan.latitudeDelta * shiftRatio
        
        let adjustedCenter = CLLocationCoordinate2D(latitude: shiftedLatitude, longitude: initialCenter.longitude)
        let region = MKCoordinateRegion(center: adjustedCenter, span: initialSpan)
        
        mapView.setRegion(region, animated: false)
    }
    
    private func renderPlaces(places:[Place]){
        isPainting$.accept(true)
        var annotations: [MKAnnotation] = places.map{
            let annotation = CustomPointAnnotation()
  
            annotation.coordinate = CLLocationCoordinate2D(latitude: $0.latitude ?? 0, longitude: $0.longitude ?? 0)
            annotation.placeId = $0.id
            if let placeType = $0.types.first{
                annotation.placeTypeName = placeType.name
            }

            annotation.title = $0.name

            return annotation
        }
        mapView.addAnnotations(annotations);
        isPainting$.accept(false)

    }
    
    private func renderGeoJson(features: [MKGeoJSONFeature]) {
        clearMapView();

        var overlays: [MKOverlay] = []
        var annotations: [MKAnnotation] = []
        var boundingMapRect = MKMapRect.null
        
        isPainting$.accept(true)
            
        
        for feature in features {
            for geometry in feature.geometry {
                var id: String?

                if let propertiesData = feature.properties {
                     do {
                         let props = try JSONDecoder().decode(GeoJsonFeatureProperties.self, from: propertiesData)
                         id = props.id
                     } catch {
                         print("⚠️ properties decode 실패:", error)
                     }
                 }
                
                if let point = geometry as? MKPointAnnotation {
                    
                    
                    let annotation = CustomPointAnnotation()
                    annotation.coordinate = geometry.coordinate
                    annotation.placeId = id?.split(separator: ".").first.map { String($0) }

                    annotations.append(annotation)

                    let pointRect = MKMapRect(origin: MKMapPoint(annotation.coordinate), size: MKMapSize(width: 1000, height: 1000))
                    boundingMapRect = boundingMapRect.union(pointRect)
                } else if let polyline = geometry as? MKPolyline {
                    overlays.append(polyline)
                    boundingMapRect = boundingMapRect.union(polyline.boundingMapRect)
                } else if let polygon = geometry as? MKPolygon {
                    overlays.append(polygon)
                    boundingMapRect = boundingMapRect.union(polygon.boundingMapRect)
                }
            }
        }

        mapView.addOverlays(overlays)
        mapView.addAnnotations(annotations)

        if !boundingMapRect.isNull {
            var region = MKCoordinateRegion(boundingMapRect)

            // ✅ 최소 줌 보정 (너무 좁은 경우 대비)
            let minSpan: CLLocationDegrees = 1 // 100km
            region.span.latitudeDelta = max(region.span.latitudeDelta, minSpan)
            region.span.longitudeDelta = max(region.span.longitudeDelta, minSpan)

            // ✅ 중심 좌표 보정: 위에서 75% 지점으로 이동
            let latitudeShiftRatio: CLLocationDegrees = 0.5  // 위로 50% 이동 == 아래쪽 50%
            let shiftedLatitude = region.center.latitude - region.span.latitudeDelta * latitudeShiftRatio
            let adjustedCenter = CLLocationCoordinate2D(latitude: shiftedLatitude, longitude: region.center.longitude)
            region.center = adjustedCenter

            mapView.setRegion(region, animated: true)
        }
        
        
        
        isPainting$.accept(false)

    }

    
    

}


extension MainViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .blue
            renderer.lineWidth = 2
            return renderer
        }

        if let polygon = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.strokeColor = .red
            renderer.fillColor = UIColor.red.withAlphaComponent(0.3)
            renderer.lineWidth = 1
            return renderer
        }

        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }

        let identifier = "CustomMarker"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }

        // ✅ cast to our custom annotation
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)


        
        if let customAnnotation = annotation as? CustomPointAnnotation {
            let placeType = customAnnotation.placeTypeName

            if let placeId = customAnnotation.placeId {
                
                if(selectedPlaceId == placeId){
                    annotationView?.glyphImage = UIImage(systemName: "checkmark.circle", withConfiguration: config)
                }
                
                else{
                    if let placeTypeName = customAnnotation.placeTypeName?.rawValue {
                        annotationView?.glyphImage = UIImage(named:placeTypeName)
                    }
                    else{
                        annotationView?.glyphImage = UIImage(systemName: "questionmark.circle", withConfiguration: config)
                    }
                   

                }
            }   else {

                annotationView?.glyphImage = UIImage(systemName: "record.circle", withConfiguration: config)

            }
        }

        annotationView?.markerTintColor = .white
        annotationView?.glyphTintColor = .primaryViolet
        return annotationView
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation as? CustomPointAnnotation else { return }

        if let placeId = annotation.placeId {
            placeAnnotationTapped$.accept(placeId)
        } else {
            print("❓ placeId가 없음 (아마도 일반 참고용 위치)")
        }
    }
    
}

final class CustomPointAnnotation: MKPointAnnotation {
    var placeId: String?
    var placeTypeName: PlaceName?

}


