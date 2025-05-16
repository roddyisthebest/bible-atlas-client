//
//  CreateVoteDetailViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/26/25.
//

import UIKit
import MapKit
import MarkdownView
import Markdown

class CreateVoteDetailViewController: UIViewController {
    
    
    private let oldMarkdown = """
        <style>
        body { color: white !important; }
        </style>

        ### **🔹 로컬에서 배포하는 방법**

        GitHub Actions을 사용하지 않고, 로컬에서 직접 배포를 실행할 수도 있습니다.

        아래는 환경별 배포 명령어입니다.

        #### **Curation 배포**

        -   **스테이징 배포**
            ```bash
            yarn deploy:curation:stage
            ```
        -   **프로덕션 배포**
            ```bash
            yarn predeploy:curation:prod  # 빌드 전 기존 dist 삭제 후 빌드 실행
            yarn deploy:curation:prod     # 배포 실행
            ```

        #### **Partners 배포**

        -   **스테이징 배포**
            ```bash
            yarn predeploy:partners:stage  # 빌드 전 기존 dist 삭제 후 빌드 실행
            yarn deploy:partners:stage     # 배포 실행
            ```
        -   **프로덕션 배포**
            ```bash
            yarn predeploy:partners:prod  # 빌드 전 기존 dist 삭제 후 빌드 실행
            yarn deploy:partners:prod     # 배포 실행
            ```

        각 배포 스크립트는 `./scripts/` 디렉터리 내 `.sh` 파일을 실행하며, 해당 스크립트를 참고하여 배포 로직을 조정할 수 있습니다.

        로컬에서 배포 시, 위 명령어를 실행하면 해당 환경(`stage` 또는 `prod`)에 맞게 애플리케이션이 빌드되고 업로드됩니다. 🚀

        """
    
    
    private lazy var scrollView = {
        let sv = UIScrollView();

        view.addSubview(sv)
        sv.addSubview(contentView)

        sv.alwaysBounceVertical = true
        sv.showsVerticalScrollIndicator = true
        sv.showsHorizontalScrollIndicator = false
        
        return sv;
    }()
    
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.addSubview(containerView)
        return view
    }()
    
    
    private lazy var containerView = {
        let cv = UIView();
        
        cv.addSubview(titleContainerView)
        cv.addSubview(seperatorView)
        cv.addSubview(contentContainerView)
        cv.backgroundColor = .wrapperGray
        cv.layer.cornerRadius = 8;
        return cv;
    }()
    
    
    
    private lazy var titleContainerView = {
        let cv = UIView();
        cv.addSubview(titleStackView)
        cv.addSubview(dotButton)

        return cv;
    }()
    
    private lazy var contentContainerView = {
        let cv = UIView();
        cv.addSubview(mapView)
        cv.addSubview(md)
        return cv;
    }()
    
    
    private let mapView: MKMapView = {
        let mv = MKMapView();
        mv.autoresizingMask = [.flexibleWidth, .flexibleHeight];
        mv.layer.cornerRadius = 8;
        mv.layer.masksToBounds = true

        return mv;
    }()

    
    private lazy var titleStackView = {
        let sv = UIStackView(arrangedSubviews: [statusView, titleContentStackView]);
        sv.axis = .horizontal;
        sv.spacing = 12;
        sv.alignment = .center
        
        return sv;
    }()
    
    private lazy var statusView = {
        let v = UIView();
        v.layer.cornerRadius = 25;
        v.layer.masksToBounds = true;
        v.backgroundColor = .activityCreationBGColor
        v.addSubview(statusLabel)
        return v;
    }()
    
    private let statusLabel = {
        let label = UILabel();
        label.font = UIFont.boldSystemFont(ofSize: 20);
        label.textColor = .activityCreationTextColor;
        label.text = "생성"
        return label;
    }()
    
    private lazy var titleContentStackView = {
        let sv = UIStackView(arrangedSubviews: [titleLabel, subContentStackView])
        sv.axis = .vertical
        sv.spacing = 4
        sv.alignment = .leading
        
        return sv
    }()
    
    private let titleLabel = {
        let label = UILabel();
        label.font = UIFont.boldSystemFont(ofSize: 16);
        label.textColor = .white;
        label.text = "달리치안소 달리치안소"
        return label;
    }()
    
    private lazy var subContentStackView = {
        let sv = UIStackView(arrangedSubviews: [timeLabel, voteResultWrapperStackView]);
        sv.axis = .horizontal;
        sv.spacing = 12;
        sv.alignment = .center
        
        return sv;
    }()
    
    
    private let timeLabel = {
        let label = UILabel();
        label.text = "10분전"
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = .white
        return label;
    }()

    
    private lazy var voteResultWrapperStackView = {
        let sv = UIStackView(arrangedSubviews: [voteUpResultStackView, voteDownResultStackView, userStackView]);
        sv.axis = .horizontal;
        sv.spacing = 6;
        sv.alignment = .center
        
        return sv;
    }();
    
    
    private lazy var voteUpResultStackView = {
        let sv = UIStackView(arrangedSubviews: [voteUpResultIcon, voteUpResultLabel]);
        sv.axis = .horizontal;
        sv.spacing = 3;
        sv.alignment = .center
        return sv;
    }()
    
    private let voteUpResultIcon = {
        let image = UIImage(systemName: "arrow.up")
        let icon = UIImageView(image:image)
        icon.tintColor = .upIconColor
        return icon;
    }()
    
    private let voteUpResultLabel = {
        let label = UILabel();
        label.text = "10"
        label.textColor = .white;
        label.font = UIFont.systemFont(ofSize: 13)
        return label
    }()
    
    
    private lazy var voteDownResultStackView = {
        let sv = UIStackView(arrangedSubviews: [voteDownResultIcon, voteDownResultLabel]);
        sv.axis = .horizontal;
        sv.spacing = 3;
        sv.alignment = .center
        
        return sv;
    }()
    
    
    private let voteDownResultIcon = {
        let image = UIImage(systemName: "arrow.down")
        let icon = UIImageView(image:image)
        icon.tintColor = .downIconColor
        return icon;
    }()
    
    private let voteDownResultLabel = {
        let label = UILabel();
        label.text = "10"
        label.textColor = .white;
        label.font = UIFont.systemFont(ofSize: 13)
        return label
    }()
    
    
    private lazy var userStackView = {
        let sv = UIStackView(arrangedSubviews: [userImageView, userLabel]);
        sv.axis = .horizontal;
        sv.spacing = 6;
        sv.alignment = .center
        
        return sv;
    }()
    
    private let userImageView = {
        let image = UIImage(systemName: "person.circle")
        let iv = UIImageView(image:image)
        return iv;
    }()
    
    private let userLabel = {
        let label = UILabel();
        label.text = "shy"
        label.textColor = .white;
        label.font = UIFont.systemFont(ofSize: 13)
        return label
    }()
    
    private let dotButton = {
        let button = UIButton();
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold, scale: .large)

        let dotImage = UIImage(systemName: "ellipsis",withConfiguration: imageConfig)?.withTintColor(.white, renderingMode: .alwaysOriginal);
        button.setImage(dotImage, for: .normal)
        button.transform = CGAffineTransform(rotationAngle: .pi / 2)
        return button;
    }()
    
    private let seperatorView = {
        let sv = UIView();
        sv.backgroundColor = .tabbarGray;
        
        return sv;
    }();
    
//    private let contentTextView = {
//        let tv = UITextView();
//        tv.textColor = .white;
//        tv.font = UIFont.systemFont(ofSize: 14)
//        tv.text = "sdddasasdasdsdㅇㄹㄴㅇㅁㄹㅁ dkssuddkdsasfd asdasdfasdfasdfasdfasdfasdfsdfsdfsdfdsf"
//        tv.backgroundColor = .clear
//        tv.isScrollEnabled = false;
//        tv.isEditable = false;
//        return tv;
//    }()

    private let md = {
        let md = MarkdownView();
        md.isScrollEnabled = false
        return md;
    }()

    private let bottomStackHeight = 115;
    
    private lazy var bottomContainerView = {
        let v = UIView();
        v.backgroundColor = .thirdGray;
        v.layer.cornerRadius = 8
        v.layer.masksToBounds = true
        view.addSubview(v)
        v.addSubview(bottomStackView)
        
        return v;
    }()
    
    private lazy var bottomStackView = {
        let sv = UIStackView(arrangedSubviews: [agreeButton, disagreeButton]);
        sv.axis = .horizontal;
        sv.distribution = .fillEqually;
        sv.alignment = .fill
        sv.spacing = 20
        return sv;
    }()
    
    
    // TODO: button component화 하기
    private lazy var agreeButton = {
        let button = UIButton();
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 8
        button.backgroundColor = .tabbarGray
        button.addSubview(agreeButtonStatusStackView)
        button.addSubview(agreeButtonLabel)
        return button;
    }();
    
 
    
    
    private let agreeButtonLabel = {
        let label = UILabel();
        label.font = UIFont.boldSystemFont(ofSize: 18);
        label.textColor = .white;
        label.textAlignment = .center
        label.text = "찬성하기"
        return label;
    }()
    
    private lazy var agreeButtonStatusStackView = {
        let sv = UIStackView(arrangedSubviews: [agreeButtonIcon, agreeButtonStatusLabel ])
        sv.axis = .horizontal;
        sv.distribution = .fill;
        sv.alignment = .center
        sv.spacing = 4
        return sv;
    }()
    private let agreeButtonIcon = {
        let image = UIImage(systemName: "arrow.up")
        let icon = UIImageView(image:image)
        icon.tintColor = .upIconColor
        return icon;
    }()
    
    private let agreeButtonStatusLabel = {
        let label = UILabel();
        label.font = UIFont.boldSystemFont(ofSize: 18);
        label.textColor = .white;
        label.text = "10"
        return label;
    }()
    
   
    
    
    
    
    private lazy var disagreeButton = {
        let button = UIButton();
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1;
        button.layer.borderColor = UIColor.primaryViolet.cgColor
        button.backgroundColor = .thirdGray
        button.addSubview(disagreeButtonStatusStackView)
        button.addSubview(disagreeButtonLabel)
        return button;
    }();
    
    private let disagreeButtonLabel = {
        let label = UILabel();
        label.font = UIFont.boldSystemFont(ofSize: 18);
        label.textColor = .white;
        label.textAlignment = .center
        label.text = "반대하기"
        return label;
    }()
    
    private lazy var disagreeButtonStatusStackView = {
        let sv = UIStackView(arrangedSubviews: [disagreeButtonIcon, disagreeButtonStatusLabel ])
        sv.axis = .horizontal;
        sv.distribution = .fill;
        sv.alignment = .center
        sv.spacing = 4
        return sv;
    }()
    private let disagreeButtonIcon = {
        let image = UIImage(systemName: "arrow.down")
        let icon = UIImageView(image:image)
//        icon.tintColor = .downIconColor
        icon.tintColor = .primaryViolet
        return icon;
    }()
    
    private let disagreeButtonStatusLabel = {
        let label = UILabel();
        label.font = UIFont.boldSystemFont(ofSize: 18);
        label.textColor = .white;
        label.textColor = .primaryViolet

        label.text = "10"
        return label;
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI();
        setupMapView();
        setupMarkdownView()
        setupConstraints()

    }
    
    
    private func setupMapView(){
        centerMapOnLocation(latitude: 37.7749, longitude: -122.4194)
        addAnnotation(latitude: 37.7749, longitude: -122.4194, title: "샌프란시스코", subtitle: "골든 게이트 브리지 근처")
    }
    
    private func setupUI(){
        view.backgroundColor = .tabbarGray;
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
    
    func parseMarkdown(_ text: String) -> Document {
        return Document(parsing: text)
    }
    
    
    private func setupMarkdownView(){
        md.load(markdown: oldMarkdown)
    }
    
    private func setupConstraints(){
        
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide);
        }

        
        contentView.snp.makeConstraints { make in
            make.bottom.trailing.leading.equalTo(scrollView.contentLayoutGuide)
            make.top.equalTo(scrollView.contentLayoutGuide).offset(0)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
            make.bottom.equalToSuperview().inset(bottomStackHeight);
        }
        
        titleContainerView.snp.makeConstraints { make in
            make.height.equalTo(100);
            make.top.equalToSuperview()
            make.trailing.leading.equalToSuperview()

        }
        
        
        seperatorView.snp.makeConstraints { make in
            make.height.equalTo(1);
            make.top.equalTo(titleContainerView.snp.bottom);
            make.trailing.leading.equalToSuperview()
        }
        
        contentContainerView.snp.makeConstraints { make in
            make.top.equalTo(seperatorView.snp.bottom).offset(20);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
            make.bottom.equalToSuperview().inset(20)
        }
        
        mapView.snp.makeConstraints { make in
            make.height.equalTo(200);
            make.top.equalToSuperview();
            make.trailing.leading.equalToSuperview()

        }
        
        
        md.snp.makeConstraints { make in
            make.top.equalTo(mapView.snp.bottom).offset(20);
            make.trailing.leading.equalToSuperview()
            make.bottom.equalToSuperview().priority(.low)
        }
        
        dotButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20);
            make.centerY.equalToSuperview()
        }
        
        
        titleStackView.snp.makeConstraints{make in
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
            make.centerY.equalToSuperview();
        }
        
    
        statusView.snp.makeConstraints{make in
            make.width.height.equalTo(50);
        }
        
        statusLabel.snp.makeConstraints{make in
            make.center.equalToSuperview();
        }
        
        voteUpResultIcon.snp.makeConstraints{make in
            make.width.equalTo(15)
            make.height.equalTo(17.5)
        }
        
        voteDownResultIcon.snp.makeConstraints{make in
            make.width.equalTo(15)
            make.height.equalTo(17.5)
        }
        
        bottomContainerView.snp.makeConstraints { make in
            make.height.equalTo(bottomStackHeight);
            make.bottom.equalToSuperview()
            make.trailing.leading.equalToSuperview()
        }
        
        bottomStackView.snp.makeConstraints { make in
            
            make.top.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom);
        }
        
        agreeButtonStatusStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20);
            make.centerY.equalToSuperview()
        }
        
        agreeButtonLabel.snp.makeConstraints { make in
            make.leading.equalTo(agreeButtonStatusStackView.snp.trailing).offset(20);
            make.trailing.equalToSuperview().inset(20);
            make.centerY.equalToSuperview()
        }
        
        agreeButtonIcon.snp.makeConstraints{make in
            make.width.equalTo(20)
            make.height.equalTo(25)
        }
        
        
        disagreeButtonStatusStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20);
            make.centerY.equalToSuperview()
        }
        
        disagreeButtonLabel.snp.makeConstraints { make in
            make.leading.equalTo(disagreeButtonStatusStackView.snp.trailing).offset(20);
            make.trailing.equalToSuperview().inset(20);
            make.centerY.equalToSuperview()
        }
        
        disagreeButtonIcon.snp.makeConstraints{make in
            make.width.equalTo(20)
            make.height.equalTo(25)
        }
        
    }
    
}
