//
//  CreateVoteDetailViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/26/25.
//

import UIKit
import MapKit
import MarkdownView

class CreateVoteDetailViewController: UIViewController {

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
        button.backgroundColor = .tabbarGray
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
        icon.tintColor = .downIconColor
        return icon;
    }()
    
    private let disagreeButtonStatusLabel = {
        let label = UILabel();
        label.font = UIFont.boldSystemFont(ofSize: 18);
        label.textColor = .white;
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
    
    private func setupMarkdownView(){
        md.load(markdown: """
        <style>
        body { color: white !important; }
        </style>
        # **securenet-front monorepo**

        이 프로젝트는 [NX monorepo](https://nx.dev/) 템플릿을 사용하여 [LEMONCLOUD](https://lemoncloud.io/)에서 생성되었으며, **React**만을 프론트엔드 라이브러리로 사용합니다.

        ---

        ## **설치 (의존성 추가 방법)**

        ```bash
        yarn
        ```

        ---

        ## **실행 방법**

        ### **curation 실행**

        ```bash
        $ yarn start:curation
        # 포트: 4700
        ```

        ### **admin 실행**

        ```bash
        $ yarn start:admin
        # 포트: 4702
        ```

        ### **partners 실행**

        ```bash
        $ yarn start:partners
        # 포트: 4701
        ```

        ---

        ## **📁 폴더 구조**

        이 프로젝트는 **NX monorepo** 구조를 따르며, `apps` 디렉터리 내에 **3개의 개별 애플리케이션**이 포함되어 있습니다.

        ### **📌 apps/** _(각 개별 애플리케이션 폴더)_

        -   `admin/` - **관리자(Admin) 대시보드**
        -   `curation/` - **큐레이션 서비스**
        -   `partners/` - **파트너 전용 서비스**

        각 애플리케이션의 **빌드 및 테스트 설정은 `project.json` 파일에서 확인**할 수 있습니다.

        ---

        ### **📌 공통 디렉터리 구조 (`src/app/` 내부)**

        각 애플리케이션(`admin`, `curation`, `partners`)은 아래와 같은 공통적인 구조를 가집니다.

        ```
        src/app/
         ├── components/   # 각 애플리케이션에서 공통으로 사용될 컴포넌트 모음
         ├── features/     # 기능(feature) 단위로 나뉘어진 페이지, 컴포넌트, 라우터 구조
         ├── layouts/      # 특정 라우트(페이지)의 레이아웃 구성
         ├── routes/       # 애플리케이션의 라우터 설정 관련 코드
        ```

        -   **`components/`** - 버튼, 입력 필드 등 공통 UI 컴포넌트 저장
        -   **`features/`** - 로그인, 대시보드, 프로필 등 개별 기능을 담당하는 컴포넌트 및 라우트 관리
        -   **`layouts/`** - 헤더, 사이드바 등 공통적인 페이지 레이아웃 저장
        -   **`routes/`** - `react-router`를 사용한 애플리케이션의 라우팅 설정

        ---

        ### **📌 libs/** _(공통 모듈)_

        모노레포 내 **여러 애플리케이션에서 공통적으로 사용되는 모듈들**이 `libs/` 디렉터리에 존재합니다.

        -   **`api/`** - API 요청을 관리하는 모듈 (`lemon-web-core` 활용)
        -   **`queries/`** - `react-query` 관련 쿼리 로직
        -   **`shared-ui/`** - 여러 애플리케이션에서 공통으로 사용하는 UI 컴포넌트

        ---

        ## **📡 API 요청 처리 방식**

        이 프로젝트에서는 **API 요청 처리를 `lemon-web-core`와 `react-query`를 활용하여 관리**합니다.

        1. **`lemon-web-core` 활용 (`api/` 모듈)**

            - API 요청 처리는 [`lemon-web-core`](https://github.com/lemoncloud-io/lemon-web-core) 모듈을 활용하여 수행됩니다.
            - `lemon-web-core`는 RESTful API 호출을 위한 공통 유틸리티를 제공합니다.

        2. **`react-query` 활용 (`queries/` 모듈)**
            - API 호출 후 상태 관리는 `react-query`를 사용하여 최적화합니다.
            - 캐싱, 리패치, 에러 핸들링을 효율적으로 관리할 수 있습니다.

        이렇게 구성된 구조를 활용하여, API 요청과 데이터 상태 관리를 일관되게 수행하며, 유지보수성을 높일 수 있습니다. 🚀

        ---

        ## **🚀 배포 방법**

        배포 파이프라인은 **GitHub Actions**를 사용하여 구축되었습니다. 아래는 배포 방법에 대한 상세한 설명입니다.

        ### **🔹 GitHub Actions을 통한 자동 배포**

        배포는 `.github/workflows/` 디렉토리 내 **GitHub Actions** 설정을 기반으로 실행됩니다.

        1. **⚙️ GitHub Action 설정**

            - 특정 브랜치(`develop` 또는 `main` 등)에서 푸시 또는 머지(Merge)될 때 자동으로 실행됩니다.

        2. **🔄 코드 체크아웃**

            - GitHub Actions가 Ubuntu 환경에서 코드를 체크아웃합니다.

        3. **🔧 Vite를 이용한 빌드**

            - Vite를 사용하여 프로덕션용 빌드 파일을 생성합니다.

        4. **📦 S3 업로드**

            - 빌드된 파일을 S3 버킷에 업로드하여 배포합니다.

        5. **📱 Slack 알림**
            - 배포가 완료되면 Slack을 통해 팀원들에게 성공적인 배포와 버전 정보를 알립니다.

        ---

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

        """)


        
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
