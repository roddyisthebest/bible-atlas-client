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


    
    private let disposeBag = DisposeBag();
    
    private let viewLoaded$ = PublishRelay<Void>()
    
    
    private var selectedPlaceId:String? = nil;
    
    private let placeAnnotationTapped$ = PublishRelay<String>();
    
    private let isPainting$ = BehaviorRelay<Bool>(value: false);

    private let delta = 0.25
    
    private var mapView = {
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
    
            
    init(vm:MainViewModelProtocol?) {
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
    
    func present(vc: UIViewController, animated: Bool) {
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
        let initialSpan = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
        
        let shiftRatio: CLLocationDegrees = 0.5  // 위로 50% 이동
        let shiftedLatitude = initialCenter.latitude - initialSpan.latitudeDelta * shiftRatio
        
        let adjustedCenter = CLLocationCoordinate2D(latitude: shiftedLatitude, longitude: initialCenter.longitude)
        let region = MKCoordinateRegion(center: adjustedCenter, span: initialSpan)
        
        mapView.setRegion(region, animated: false)
    }
    
    private func renderPlaces(places:[Place]){
        isPainting$.accept(true)
        let annotations: [MKAnnotation] = places.map{
            let annotation = CustomPointAnnotation()
  
            annotation.coordinate = CLLocationCoordinate2D(latitude: $0.latitude ?? 0, longitude: $0.longitude ?? 0)
            annotation.placeId = $0.id
            if let placeType = $0.types.first{
                annotation.placeTypeName = placeType.name
            }
            

            annotation.title = L10n.isEnglish ? $0.name : $0.koreanName

            return annotation
        }
        mapView.addAnnotations(annotations);
        isPainting$.accept(false)

    }
    
    private func zoomOut() {
        let center = mapView.centerCoordinate
        let span = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: 2.0)
        let region = MKCoordinateRegion(center: center, span: span)
        
        let mapRect = MKMapRect(for: region) // ✅ 핵심 수정 부분

        let height = mapView.bounds.height

        let padding = UIEdgeInsets(
            top: height * 0.25,
            left: 0,
            bottom: height * 0.75,
            right: 0
        )

        mapView.setVisibleMapRect(mapRect, edgePadding: padding, animated: true)
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
                var possibility: Int?
                var isParent: Bool?

                if let propertiesData = feature.properties {
                    do {
                        let props = try JSONDecoder().decode(GeoJsonFeatureProperties.self, from: propertiesData)
                        id = props.id
                        possibility = props.possibility
                        isParent = props.isParent
                    } catch {
                        print("⚠️ properties decode 실패:", error)
                    }
                }

                if let point = geometry as? MKPointAnnotation {
                    // GeoJSON은 MKPoint가 옴 (MKPointAnnotation 아님!)
                    let ann = CustomPointAnnotation()
                    ann.coordinate = point.coordinate
                    ann.placeId = id?.split(separator: ".").first.map { String($0) }
                    ann.possibility = possibility
                    ann.isParent = isParent
                    annotations.append(ann)

                    let r = MKMapRect(origin: MKMapPoint(ann.coordinate),
                                      size: MKMapSize(width: 10, height: 10))
                    boundingMapRect = boundingMapRect.union(r)

                } else if let polyline = geometry as? MKPolyline {
                    overlays.append(polyline)
                    boundingMapRect = boundingMapRect.union(polyline.boundingMapRect)

                } else if let multipolyline = geometry as? MKMultiPolyline {
                    overlays.append(multipolyline)
                    boundingMapRect = boundingMapRect.union(multipolyline.boundingMapRect)

                } else if let polygon = geometry as? MKPolygon {
                    overlays.append(polygon)
                    boundingMapRect = boundingMapRect.union(polygon.boundingMapRect)

                } else if let multipolygon = geometry as? MKMultiPolygon {
                    overlays.append(multipolygon)
                    boundingMapRect = boundingMapRect.union(multipolygon.boundingMapRect)
                }
            }

        }

        mapView.addOverlays(overlays)
        mapView.addAnnotations(annotations)

        if !boundingMapRect.isNull {

            let mapViewHeight = mapView.bounds.height
            let bottomSheetHeight = mapViewHeight * 0.5
            let paddingValue:CGFloat = 20;
            let edgePadding = UIEdgeInsets(
                top: paddingValue,
                left: paddingValue,
                bottom: bottomSheetHeight + paddingValue,
                right: paddingValue
            )
            
            let minWidth: Double = 12_500    // 최소 가로 12.5km
            let minHeight: Double = 12_500   // 최소 세로 12.5km

            var safeRect = boundingMapRect

            if boundingMapRect.size.width < minWidth || boundingMapRect.size.height < minHeight {
                let center = MKMapPoint(x: boundingMapRect.midX, y: boundingMapRect.midY)

                let newWidth = max(boundingMapRect.size.width, minWidth)
                let newHeight = max(boundingMapRect.size.height, minHeight)

                safeRect = MKMapRect(
                    origin: MKMapPoint(
                        x: center.x - newWidth / 2,
                        y: center.y - newHeight / 2
                    ),
                    size: MKMapSize(width: newWidth, height: newHeight)
                )
            }
                        
            mapView.setVisibleMapRect(safeRect, edgePadding: edgePadding, animated: true)

        }
        
        
        
        isPainting$.accept(false)

    }

    
    

}


extension MainViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        if let multiPolygon = overlay as? MKMultiPolygon {
            let r = MKMultiPolygonRenderer(multiPolygon: multiPolygon)
            r.lineWidth = 1
            r.strokeColor = UIColor.label.withAlphaComponent(0.6)
            r.fillColor = UIColor.systemBlue.withAlphaComponent(0.15)
            return r
        }

        if let polygon = overlay as? MKPolygon {
            let r = MKPolygonRenderer(polygon: polygon)
            r.lineWidth = 1
            r.strokeColor = UIColor.label.withAlphaComponent(0.6)
            r.fillColor = UIColor.systemBlue.withAlphaComponent(0.15)
            return r
        }

        if let multiPolyline = overlay as? MKMultiPolyline {
            let r = MKMultiPolylineRenderer(multiPolyline: multiPolyline)
            r.lineWidth = 2
            r.strokeColor = UIColor.primaryBlue
            return r
        }

        if let polyline = overlay as? MKPolyline {
            let r = MKPolylineRenderer(polyline: polyline)
            r.lineWidth = 2
            r.strokeColor = UIColor.primaryBlue
            return r
        }

        return MKOverlayRenderer(overlay: overlay)
    }

    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
           guard !(annotation is MKUserLocation) else { return nil }

           let id = "CustomMarker"
           let view = (mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView)
               ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
           view.annotation = annotation
           view.canShowCallout = true

           // 재사용 대비 초기화
           view.glyphImage = nil
           view.glyphText = nil
           view.glyphTintColor = .white
           view.markerTintColor = .systemGray3
           view.displayPriority = .defaultLow
           view.titleVisibility = .adaptive
           view.subtitleVisibility = .adaptive

           let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)

           if let ann = annotation as? CustomPointAnnotation {
               // 선택 상태 우선 처리
               if let placeId = ann.placeId, placeId == selectedPlaceId {
                   view.glyphImage = UIImage(systemName: "checkmark.circle", withConfiguration: config)
                   view.markerTintColor = .systemIndigo
                   view.displayPriority = .required
               } else {
                   let isHistorical = (ann.isParent == true)
                   let possibility = ann.possibility

                   if isHistorical {
                       // 과거 추정: 보조 톤 + 시계 아이콘
                       view.markerTintColor = .systemOrange   // 또는 .systemGray3
                       view.glyphImage = UIImage(systemName: "clock", withConfiguration: config)
                       view.displayPriority = .defaultLow
                   } else {
                       // 현재 추정: 강조 + 퍼센트
                       view.markerTintColor = .systemGreen
                       if let p = possibility {
                           view.glyphText = "\(p)%"
                       } else {
                           view.glyphImage = UIImage(systemName: "questionmark", withConfiguration: config)
                       }
                       view.displayPriority = .required
                   }

                   // 타입 아이콘을 꼭 쓰고 싶다면(퍼센트 대신):
                    if let name = ann.placeTypeName?.rawValue, let img = UIImage(named: name) {
                        view.glyphImage = img
                    }

                   // 말풍선 서브타이틀(퍼센트가 있을 때만)
                   if let p = possibility {
                       
                       let subtitleKr = "신뢰도 \(p)%"
                       let subtitleEn = "Confidence \(p)%"
                       ann.subtitle = L10n.isKorean ? subtitleKr : subtitleEn
                       switch(p){
                       case 100:
                           view.markerTintColor = .badge100
                           break
                       case 70...99:
                           view.markerTintColor = .badge90to70
                           break
                       case 40...69:
                           view.markerTintColor = .badge60to40
                           break
                       default:
                           view.markerTintColor = .badge30to0
                           break
                       }
                       
                   } else {
                       ann.subtitle = nil
                   }
               }
           }

           return view
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
    var placeTypeName: PlaceTypeName?
    var possibility:Int?
    var isParent:Bool?
}



#if DEBUG
extension MainViewController {
    var _test_mapView: MKMapView { mapView }
    var _test_isLoadingAnimating: Bool { loadingView.isAnimating }
    
    func _test_replaceMapView(_ mv: MKMapView) {
          // 기존 맵 제거 & 새 맵 삽입 (프레임/오토리사이즈 일치)
          mapView.removeFromSuperview()
          view.addSubview(mv)
          mv.frame = mapView.frame
          mv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
          mv.delegate = self
          mapView = mv
      }
    
    func _test_setSelected(placeId: String?) {
        selectedPlaceId = placeId
    }

    func _test_zoomOut() {
        zoomOut()
    }
    
}


#endif



