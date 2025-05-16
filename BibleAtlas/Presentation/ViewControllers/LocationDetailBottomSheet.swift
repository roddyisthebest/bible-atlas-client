//
//  LocationDetailBottomSheet.swift
//  BibleAtlas
//
//  Created by 배성연 on 3/10/25.
//

import UIKit
import MarkdownView

class LocationDetailBottomSheet: UIViewController {

    private let fullText:String = """
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

        """
    private var isExpanded = false;
    
    private lazy var container = {
        let v = UIView();
        view.addSubview(v)
        v.addSubview(titleStackView)
        v.addSubview(scrollView)
        v.backgroundColor = .thirdGray
        return v ;
    }()
    
    private lazy var titleStackView = {
        let sv = UIStackView(arrangedSubviews: [titleTextContainerStackView,titleButtonsContainerStackView]);
        sv.axis = .horizontal;
        sv.distribution = .equalSpacing;
        sv.alignment = .fill;
        sv.spacing = 8;
        return sv;
    }();
    
    
    private lazy var titleTextContainerStackView = {
        let sv = UIStackView(arrangedSubviews: [globalImage, titleTextLabel]);
        sv.axis = .horizontal;
        sv.alignment = .center;
        sv.distribution = .fill;
        sv.spacing = 10;
        return sv;
    }();
    
    
    private lazy var globalImage = {
        let image = UIImage(systemName: "globe.americas.fill");
        let iv = UIImageView(image:image);
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .primaryViolet;
        
        
        return iv;
    }()
    
    private lazy var titleTextLabel = {
        let label = UILabel();
        label.font = UIFont.systemFont(ofSize: 20, weight: .heavy);
        label.textColor = .white;
        label.lineBreakMode = .byTruncatingTail;
        label.text = "코리치안스"
        return label;
    }();
    
    
    private lazy var titleButtonsContainerStackView = {
        let sv = UIStackView(arrangedSubviews: [shareButton, deleteButton]);
        sv.axis = .horizontal;
        sv.alignment = .center;
        sv.distribution = .fill;
        sv.spacing = 8;
        return sv;
    }();
    
    private let shareButton  = {
        var config = UIButton.Configuration.plain()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        config.preferredSymbolConfigurationForImage = imageConfig
        
        let button = UIButton(configuration: config)
        
        button.setImage(UIImage(systemName: "square.and.arrow.up.fill"), for: .normal)
        button.tintColor = .white;
        button.backgroundColor = .tabbarGray;
        button.layer.cornerRadius = 10;
        return button;
    }();
    
    private let deleteButton = {
        var config = UIButton.Configuration.plain()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        config.preferredSymbolConfigurationForImage = imageConfig
        
        let button = UIButton(configuration: config)
        
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .white;
        button.backgroundColor = .tabbarGray;
        button.layer.cornerRadius = 10;
        button.addTarget(self, action: #selector(closeBottomSheet), for: .touchUpInside)
        return button;
    }();
    
    private lazy var scrollView = {
        let sv = UIScrollView();
        sv.addSubview(scrollInnerView);
        sv.backgroundColor = .thirdGray;
        return sv;
    }()
    
    private lazy var scrollInnerView = {
        let v = UIView();
        v.backgroundColor = .thirdGray;
        v.addSubview(buttonStackView)
        v.addSubview(infoLabel)
        v.addSubview(mdContainer)
        return v;
    }()
    
    private lazy var buttonStackView = {
        let sv = UIStackView(arrangedSubviews: [likeButton, moreButton]);
        
        sv.axis = .horizontal;
        sv.distribution = .fillEqually;
        sv.alignment = .fill
        sv.spacing = 10;
        
        return sv;
    }()
    
    
    private let likeButton = {
        let button = UIButton();
    
        let likeIcon = UIImage(systemName: "hand.thumbsup");
        button.layer.cornerRadius = 10;
        button.layer.borderWidth = 1;
        button.layer.masksToBounds = true;
        button.setImage(likeIcon, for: .normal);
        button.tintColor = .primaryViolet
        
        button.layer.borderColor = UIColor.primaryViolet.cgColor;

        let title = "16"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20), // Bold 폰트
            .foregroundColor: UIColor.primaryViolet // 글씨 색상
        ]
        let attributedTitle = NSAttributedString(string: title, attributes: attributes)
        button.setAttributedTitle(attributedTitle, for: .normal)
        

        var config = UIButton.Configuration.plain()
        let imageConfig = UIImage.SymbolConfiguration(weight: .bold)
        config.preferredSymbolConfigurationForImage = imageConfig

        config.imagePadding = 8 // 이미지와 텍스트 간 간격
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium) // 이미지 크기 조정
        button.configuration = config

        return button;
    }()

    
    private let moreButton = {
        let button = UIButton();
    
        let likeIcon = UIImage(systemName: "ellipsis");
        button.layer.cornerRadius = 10;
        button.layer.borderWidth = 1;
        button.layer.masksToBounds = true;
        button.setImage(likeIcon, for: .normal);
        button.tintColor = .white
        button.layer.borderColor = UIColor.tabbarGray.cgColor;
        button.backgroundColor = .tabbarGray;

        let title = "더보기"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20), // Bold 폰트
            .foregroundColor: UIColor.white // 글씨 색상
        ]
        let attributedTitle = NSAttributedString(string: title, attributes: attributes)
        button.setAttributedTitle(attributedTitle, for: .normal)
        

        var config = UIButton.Configuration.plain()
        
        let imageConfig = UIImage.SymbolConfiguration(weight: .bold)
        config.preferredSymbolConfigurationForImage = imageConfig
        config.imagePlacement = .top // 이미지가 위로 배치

        config.imagePadding = 8 // 이미지와 텍스트 간 간격
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium) // 이미지 크기 조정
        button.configuration = config

        return button;
    }()

    
    private let infoLabel = {
        let label = UILabel();
        
        label.text = "정보";
        label.font = UIFont.systemFont(ofSize: 20, weight: .heavy);
        label.textColor = .white;
        return label
    }()
    
    private lazy var mdContainer = {
        let v = UIView();
        v.layer.cornerRadius = 10;
        v.layer.masksToBounds = true;
        v.backgroundColor = .tabbarGray;
        v.addSubview(markdownView);
        v.addSubview(moreMdButton);
        return v;
    }()
    private let markdownView = MarkdownView();
    
    
    private let moreMdButton = {
        let button = UIButton();
        button.setTitle("더보기", for: .normal);
        button.addTarget(self, action: #selector(toggleMarkdown), for: .touchUpInside)
        return button;
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupConstraints();
        setupMarkdownView();
        // Do any additional setup after loading the view.
    }
    
    private func setupMarkdownView(){
        
        DispatchQueue.global(qos:.background).async {
            let previewText = self.isExpanded ? self.fullText : String(self.fullText.prefix(500)) + "..."
            
            DispatchQueue.main.async{
                if(!self.isExpanded){
                    self.markdownView.load(markdown: previewText)
                }
                else{
                    self.markdownView.show(markdown: previewText)
                }
            }
        }

      
        
        

    }
    
    @objc private func toggleMarkdown(){
        isExpanded.toggle();
        setupMarkdownView();
    }
    
    @objc private func closeBottomSheet(){
        dismiss(animated: true)
    }
    
    private func setupConstraints(){
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview();
        }
        
        
        titleStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
        }
        
        globalImage.snp.makeConstraints { make in
            make.width.height.equalTo(30)
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(titleStackView.snp.bottom).offset(20);
            make.leading.trailing.bottom.equalToSuperview();
        }
        
        scrollInnerView.snp.makeConstraints { make in
            make.width.equalToSuperview();
            make.top.bottom.equalToSuperview();
            
        }
        
        buttonStackView.snp.makeConstraints { make in
            make.top.equalToSuperview();
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
            make.height.equalTo(80);
        }
        
        infoLabel.snp.makeConstraints { make in
            make.top.equalTo(buttonStackView.snp.bottom).offset(30);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
        }
        
        mdContainer.snp.makeConstraints { make in
            make.top.equalTo(infoLabel.snp.bottom).offset(20);
            make.leading.equalToSuperview().offset(20);
            make.trailing.bottom.equalToSuperview().inset(20);
        }
        
        markdownView.snp.makeConstraints { make in
            make.top.trailing.leading.equalToSuperview();
            make.bottom.equalToSuperview().inset(40);
        }
        
        moreMdButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview();
            make.bottom.equalToSuperview().inset(20)
        }
        
    }
    

}
