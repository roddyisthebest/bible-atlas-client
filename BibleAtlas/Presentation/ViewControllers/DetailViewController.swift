//
//  DetailViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/19/25.
//

import UIKit
import MapKit
import SnapKit
import MarkdownView


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
        uv.addSubview(md)
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
    
    private let md = MarkdownView();
    
    
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView();
        setupUI();
        setupMarkdownView();
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
        
        
        md.snp.makeConstraints{make in
            make.edges.equalToSuperview()
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
