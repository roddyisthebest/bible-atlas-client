//
//  DetailViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/19/25.
//

import UIKit
import MapKit
import SnapKit
class DetailViewController: UIViewController {
    
    private var mapView: MKMapView!
        
    private lazy var contentWrapperView: UIView = {
        let cv = UIView();
        cv.backgroundColor = .backgroundDark;
        
        cv.addSubview(contentView)
        return cv;
    }()
    
    private lazy var  contentView = {
        let cv = UIView();
        cv.addSubview(titleView)
        cv.addSubview(descriptionView)
        return cv;
    }()
    
    private lazy var titleView = {
        let tv = UIView();
        tv.addSubview(globalIcon)
        tv.addSubview(titleLabel)
        tv.addSubview(dotButton)
        tv.backgroundColor = .thirdGray
        
        tv.layer.cornerRadius = 8;
        tv.layer.masksToBounds = true;
        return tv;
    }();
    
    private let globalIcon = {
        let imageView = UIImageView(image:UIImage(systemName: "globe.asia.australia.fill"));
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .primaryViolet;
        return imageView;
    }()
    
    private let dotButton = {
        let button = UIButton(type:.system);
        let image = UIImage(systemName: "ellipsis")
        button.setImage(image,for:.normal)
        button.tintColor = .primaryViolet
        button.addTarget(self, action: #selector(dotButtonTapped), for: .touchUpInside)

        return button
    }()
    
    private let titleLabel = {
        let label = UILabel();
        label.textColor = .white;
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.text = "코리치안스코리"
        label.numberOfLines = 2  // 🔹 한 줄만 표시
        label.lineBreakMode = .byTruncatingTail // 🔹 길면 "..." 표시
        return label;
    }();
    
    private var closeButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "xmark")
        button.setImage(image, for: .normal)
        button.tintColor = .primaryViolet
        button.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        button.layer.cornerRadius = 15
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var descriptionView:UIView = {
        let uv = UIView();
        uv.backgroundColor = .thirdGray
        uv.layer.cornerRadius = 8;
        uv.layer.masksToBounds = true;
        uv.addSubview(descriptionTextView)
        return uv;
    }()
    
    
    private let descriptionTextView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = .clear // ✅ 배경 투명 (필요에 따라 변경 가능)
        tv.textColor = .white
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.isScrollEnabled = true  // ✅ 스크롤 가능하게 설정
        tv.isEditable = false  // ✅ 읽기 전용 (필요하면 true로 변경)
        tv.text = "여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ여기에 설명이 들어갑니다. 죄송합니다. 너무 ㅁㄴㅇㄴㅇㄴ"
        tv.textContainerInset = UIEdgeInsets(top: 20, left: 10, bottom: 20, right: 10) // ✅ 내부 여백 추가
        return tv
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView();
        setupUI();
        centerMapOnLocation(latitude: 37.7749, longitude: -122.4194)
        addAnnotation(latitude: 37.7749, longitude: -122.4194, title: "샌프란시스코", subtitle: "골든 게이트 브리지 근처")
        setupConstraints()

    }
    
    
    private func setupMapView(){
        mapView = MKMapView(frame:view.bounds);
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight];
        view.addSubview(mapView)
    }
    
    private func setupUI(){
        view.addSubview(contentWrapperView)
        view.addSubview(closeButton)
    }
    
    private func setupConstraints(){
        mapView.snp.makeConstraints{make in
            make.leading.trailing.top.equalToSuperview();
            make.height.equalToSuperview().multipliedBy(0.35)
        }
        
        contentWrapperView.snp.makeConstraints{make in
            make.leading.trailing.bottom.equalToSuperview();
            make.top.equalTo(mapView.snp.bottom)
        }
        
        contentView.snp.makeConstraints{make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().inset(20)

            make.bottom.equalToSuperview().inset(30);
            make.top.equalToSuperview().offset(-40);
        }
        
        closeButton.snp.makeConstraints{make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10);
            make.leading.equalToSuperview().offset(20);
            make.width.height.equalTo(30)
        }
        
        titleView.snp.makeConstraints{make in
            make.top.leading.trailing.equalToSuperview();
            make.height.equalTo(80);
        }
        
        globalIcon.snp.makeConstraints{make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(20);
            make.height.width.equalTo(35)
        }
        
        titleLabel.snp.makeConstraints{make in
            make.centerY.equalToSuperview();
            make.leading.equalTo(globalIcon.snp.trailing).offset(20);
            make.trailing.equalTo(dotButton.snp.leading).offset(20);
        }
        
        dotButton.snp.makeConstraints{make in
            make.trailing.equalToSuperview().inset(20);
            make.centerY.equalToSuperview()
            make.height.width.equalTo(35)
        }
        
        descriptionView.snp.makeConstraints{make in
            make.top.equalTo(titleView.snp.bottom).offset(20);
            make.bottom.leading.trailing.equalToSuperview()
        }
        
        descriptionTextView.snp.makeConstraints{make in make.edges.equalToSuperview()
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
    
    @objc private func closeButtonTapped(){
        dismiss(animated: true)
    }
    
    @objc private func dotButtonTapped(){
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


extension UIImage {
    func rotated(by radians: CGFloat) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            context.cgContext.translateBy(x: size.width / 2, y: size.height / 2)
            context.cgContext.rotate(by: radians)
            context.cgContext.translateBy(x: -size.width / 2, y: -size.height / 2)
            draw(at: .zero)
        }
    }
}
