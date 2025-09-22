//
//  PlaceDetailViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/3/25.
//

import UIKit
import RxSwift
import RxRelay
import Kingfisher

final class Bible {
    var verses:[String] = []
    var bookName:String = "창세기"
    init(bookName:String, verses:[String]){
        self.bookName = bookName
        self.verses = verses;
    }
}
    

protocol IdentifiableBottomSheet: AnyObject {
    var bottomSheetIdentity: BottomSheetType { get }
    
}



final class PlaceDetailViewController: UIViewController {
    
    private var placeDetailViewModel:PlaceDetailViewModelProtocol?
    
    private let disposeBag = DisposeBag();
    
    private let memoButtonTapped$ = PublishRelay<Void>()
    private let placeModificationButtonTapped$ = PublishRelay<Void>();
        
    private let placeCellTapped$ = PublishRelay<String>();
    private let verseCellTapped$ = PublishRelay<String>();
    
    private let reportButtonTapped$ = PublishRelay<PlaceReportType>();
    
    
    private var relations:[PlaceRelation] = [];
    
    private var bibles:[Bible] = []
    
    
    private let placeDetailViewLoaded$ = PublishRelay<Void>();
        
    private let placeId:String
    
    private lazy var bodyView = {
        let v = UIView();
        v.isHidden = true
        v.addSubview(scrollView);
        return v;
    }()
    
    private lazy var scrollView = {
        let sv = UIScrollView();
        sv.isScrollEnabled = false
        sv.addSubview(contentView)
        return sv;
    }()
    
    
    private lazy var contentView = {
        let v = UIView()
        v.addSubview(headerStackView);
        v.addSubview(subInfoStackView)
        v.addSubview(likeAndMoreButtonsStackView)
        v.addSubview(imageButton)
        v.addSubview(descriptionStackView)
        v.addSubview(relatedLocationStackView)
        v.addSubview(relatedVerseStackView)
        v.addSubview(memoButton)
        v.addSubview(reportIssueButton)
        return v
    }()
    
    
    private lazy var headerStackView = {
        let sv = UIStackView(arrangedSubviews: [backButton, innerHeaderStackView]);
        sv.axis = .vertical;
        sv.distribution = .fill;
        sv.alignment = .fill;
        sv.spacing = 10;
        return sv;
    }()
    
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        
        let image = UIImage(systemName: "chevron.left")
        button.setImage(image, for: .normal)
        button.setTitle("back", for: .normal)
        button.setTitleColor(.primaryBlue, for: .normal)
        button.tintColor = .primaryBlue
        button.contentHorizontalAlignment = .leading // 필요 시 정렬
        return button
    }()
    
    private lazy var innerHeaderStackView = {
        let sv = UIStackView(arrangedSubviews: [titleLabel, headerButtonsStackView]);
        sv.axis = .horizontal;
        sv.distribution = .fill;
        sv.alignment = .leading;
        sv.spacing = 20;
        return sv;
    }()
    
    
    
    private let titleLabel: UILabel = {
        let label = HeaderLabel(text: "Beijing Daxing International Airport")
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    private lazy var headerButtonsStackView = {
        let sv = UIStackView(arrangedSubviews: [saveButton, shareButton, closeButton]);
        sv.axis = .horizontal;
        sv.distribution = .fill;
        sv.alignment = .fill
        sv.spacing = 8;
        return sv;
    }()
    
    private let saveButton = ToggleCircleButton(activeIconSystemName: "bookmark.fill", inActiveIconSystemName: "bookmark")
    
    private let shareButton = {
        let button = CircleButton(iconSystemName: "square.and.arrow.up");
        button.addTarget(self, action: #selector(showShareVC), for: .touchUpInside)
        return button;
    }()
    
    private let closeButton = CircleButton(iconSystemName: "xmark")
    
    private lazy var subInfoStackView = {
        let sv = UIStackView(arrangedSubviews: [placeTypeButton, filledCircleView, generationLabel]);
        sv.axis = .horizontal;
        sv.distribution = .fill
        sv.alignment = .center
        sv.spacing = 8;
        return sv;
    }()
    
    private let placeTypeButton = {
        let button = UIButton();
        button.setTitle("Type of Body", for: .normal)
        button.setTitleColor(.primaryBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)

        return button;
    }()
    
    private let filledCircleView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "circle.fill")
        imageView.tintColor = .mainText
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let generationLabel = {
        let label = UILabel();
        label.text = "ancient"
        label.textColor = .mainText
        label.font = .systemFont(ofSize: 14, weight: .medium)
        return label;
    }()
    
    private lazy var likeAndMoreButtonsStackView = {
        let sv = UIStackView(arrangedSubviews: [likeButton, moreButton])
        sv.axis = .horizontal;
        sv.distribution = .fill;
        sv.alignment = .fill
        sv.spacing = 10;
        return sv;
    }()
    
    private let likeLoadingView = LoadingView(style: .medium);
    
   
    private lazy var likeButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "hand.thumbsup.fill")
        
        button.setImage(image, for: .normal)
        button.setTitle("7 Likes", for: .normal)
        button.setTitleColor(.mainText, for: .normal)
        button.tintColor = .mainText
        button.backgroundColor = .primaryBlue
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .center // 왼쪽 정렬 필요 시
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        button.layer.cornerRadius = 8;
        button.layer.masksToBounds = true;
        button.addSubview(likeLoadingView)
        return button
    }()
    
    private lazy var moreButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "ellipsis") // 예시 아이콘
        button.setImage(image, for: .normal)
        button.tintColor = .primaryBlue // 필요 시
        button.layer.cornerRadius = 8;
        button.layer.masksToBounds = true
        button.backgroundColor = .circleButtonBkg
        button.menu = buildMoreMenu()
        button.showsMenuAsPrimaryAction = true

        return button
    }()
    
    
    private let placeImageView = {
        let iv = UIImageView();
        
        iv.contentMode = .scaleAspectFill;
        iv.clipsToBounds = true;
        return iv;
    }()
    
    private lazy var imageButton = {
        let button = UIButton(type:.system);
        button.addSubview(placeImageView)
        button.backgroundColor = .gray;
        button.layer.cornerRadius = 8;
        button.layer.masksToBounds = true
        return button;
    }()
    
    private lazy var descriptionStackView = {
        let sv = UIStackView(arrangedSubviews: [descriptionLabel, descriptionView]);
        sv.axis = .vertical;
        sv.distribution = .fill
        sv.alignment = .fill;
        sv.spacing = 10;
        return sv;
    }()
    
    private let descriptionLabel = {
        let label = HeaderLabel(text: "Description")
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        return label
    }()
    
    
    private lazy var descriptionView:UIView = {
        let uv = UIView();
        uv.backgroundColor = .mainButtonBkg;
        uv.layer.cornerRadius = 8;
        uv.layer.masksToBounds = true;
        uv.addSubview(descriptionTextView)
        return uv;
    }()
    
    
    private let descriptionTextView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = .clear // ✅ 배경 투명 (필요에 따라 변경 가능)
        tv.textColor = .mainText
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.isScrollEnabled = false
        tv.isEditable = false  // ✅ 읽기 전용 (필요하면 true로 변경)
        tv.text = "인사까지 연습했는데 거기까지 문제 없었는데 왜 니 앞에서면 바보처럼 웃게되 평소처럼만 하면 돼 음 자연스러웟어 우워 안녕안녕"
        tv.textContainerInset = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10) // ✅ 내부 여백 추가
        tv.isSelectable = false
        return tv
    }()
    
    private lazy var relatedLocationStackView = {
        let sv = UIStackView(arrangedSubviews: [relatedLocationLabel, relatedPlaceTable, relatedPlaceEmptyView]);
        sv.axis = .vertical;
        sv.distribution = .fill
        sv.alignment = .fill;
        sv.spacing = 15;
        return sv;
    }()
    
    private let relatedLocationLabel = {
        let label = HeaderLabel(text: "Related Locations")
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        return label
    }()
    
    
    private lazy var relatedPlaceTable:UITableView = {
        let tv = UITableView();
        tv.register(RelatedPlaceTableViewCell.self, forCellReuseIdentifier: RelatedPlaceTableViewCell.identifier);
        tv.delegate = self;
        tv.dataSource = self;
        tv.isScrollEnabled = false;
        
        tv.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)

        tv.backgroundColor = .mainItemBkg
        tv.layer.cornerRadius = 10;
        tv.layer.masksToBounds = true;
        tv.rowHeight = 80
        return tv;
    }()
    
    private lazy var relatedPlaceEmptyView:UIView = {
        let v = UIView();
        v.addSubview(relatedPlaceEmptyLabel)
        v.backgroundColor = .mainItemBkg
        v.layer.cornerRadius = 10;
        v.layer.masksToBounds = true;
        v.isHidden = true;
        return v;
    }()
    
    private let relatedPlaceEmptyLabel = EmptyLabel(text:"연관된 장소가 없습니다.")
    
    

    
    private lazy var memoButton:UIButton = {
        let button = UIButton(type:.system);
        button.backgroundColor = .mainItemBkg
        button.addSubview(memoStackView)
        button.layer.cornerRadius = 8;
        button.layer.masksToBounds = true
        return button;
    }()
    
    private lazy var memoStackView:UIStackView = {
        let sv = UIStackView(arrangedSubviews: [userAvatarView, memoLabel] );
        sv.axis = .horizontal
        sv.distribution = .fill;
        sv.alignment = .center;
        sv.spacing = 10;
        sv.isUserInteractionEnabled = false
        return sv;
    }()
    
    private let avatarImageView = {
        let iv = UIImageView();
        
        iv.contentMode = .scaleAspectFill;
        iv.clipsToBounds = true;
        return iv;
    }()
    
    private lazy var userAvatarView = {
        let v = UIView()
        
        v.backgroundColor = .userAvatarBkg;
        v.layer.cornerRadius = 20;
        v.layer.masksToBounds = true;
        v.addSubview(avatarImageView)

        return v
    }()
    
    private let memoLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear // ✅ 배경 투명 (필요에 따라 변경 가능)
        label.textColor = .mainText
        label.font = UIFont.systemFont(ofSize: 16)

        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail

        label.text = "인사까지 연습했는데 거기까진 문제없었는데 니 앞에서면"

        return label
    }()
    
    private lazy var detailStackView:UIStackView = {
        let sv = UIStackView(arrangedSubviews: [detailLabel]);
        sv.axis = .vertical;
        sv.distribution = .fill
        sv.alignment = .fill
        sv.spacing = 10;
        return sv;
    }()
    
    private let detailLabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .detailLabelText
        return label
    }()
    
    private lazy var reportIssueButton = {
        let button = IconTextButton(iconSystemName: "exclamationmark.bubble.fill", color: .primaryBlue, labelText: "Report an issue");
        button.menu = buildIssueReportMenu();
        button.showsMenuAsPrimaryAction = true
        return button;
    }()
    
    private lazy var relatedVerseStackView = {
        let sv = UIStackView(arrangedSubviews: [relatedVerseLabel, relatedVerseTable, relatedVerseEmptyView]);
        sv.axis = .vertical;
        sv.distribution = .fill
        sv.alignment = .fill;
        sv.spacing = 15;
        return sv;
    }()
    
    private let relatedVerseLabel = {
        let label = HeaderLabel(text: "Related Verse")
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        return label
    }()
    
    
    private lazy var relatedVerseEmptyView:UIView = {
        let v = UIView();
        v.addSubview(relatedVerseEmptyLabel)
        v.backgroundColor = .mainItemBkg
        v.layer.cornerRadius = 10;
        v.layer.masksToBounds = true;
        v.isHidden = true;
        return v;
    }()
    
    private let relatedVerseEmptyLabel = EmptyLabel(text:"언급된 성경말씀이 없습니다.")
    
    
    private lazy var relatedVerseTable:UITableView = {
        let tv = UITableView();
        tv.register(RelatedVerseTableViewCell.self, forCellReuseIdentifier: RelatedVerseTableViewCell.identifier);
        tv.delegate = self;
        tv.dataSource = self;
        tv.isScrollEnabled = false;
        
        tv.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)

        tv.backgroundColor = .mainItemBkg
        tv.layer.cornerRadius = 10;
        tv.layer.masksToBounds = true;
  
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 100
        return tv;
    }()
    
    private let loadingView = LoadingView();

    private let errorRetryView = ErrorRetryView(closable: true);

    
    init(placeDetailViewModel:PlaceDetailViewModelProtocol, placeId:String) {
        self.placeId = placeId;
        self.placeDetailViewModel = placeDetailViewModel;
        
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSheet(){
        if let sheet = self.sheetPresentationController {
            sheet.delegate = self
        }
    }
    
    private func scrollUp(){
        self.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    
    private func setAvatarImage(urlString: String) {
        let replaced = urlString.replacingOccurrences(of: "svg", with: "png")

        guard let url = URL(string: replaced) else { return }
        
        avatarImageView.kf.setImage(
            with: url,
            options: [
                .transition(.fade(0.2))
            ],
            completionHandler: { result in
//                switch result {
//                case .success(let value):
//                    print("✅ Avatar image loaded: \(value.source.url?.absoluteString ?? "")")
//                case .failure(let error):
//                    print("❌ Avatar image load failed: \(error.localizedDescription)")
//                }
            }
        )

    }
    
    private func setPlaceImage(imageTitle:String?){
        let imageEndpoint = "https://a.openbible.info/geo/images/512"
        guard let imageTitle = imageTitle else {return}
        guard let url = URL(string: "\(imageEndpoint)/\(imageTitle)") else {return}
        
        
        placeImageView.kf.setImage(with: url, options: [
            .transition(.fade(0.01))
        ],
        completionHandler: { result in
                switch result {
                case .success(let value):
                    print("✅ Place image loaded: \(value.source.url?.absoluteString ?? "")")
                case .failure(let error):
                    print("❌ Place image load failed: \(error.localizedDescription)")
                }
        })
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        relatedPlaceTable.reloadData()
        relatedPlaceTable.layoutIfNeeded()

        let relatedPlaceTableHeight = relatedPlaceTable.contentSize.height
        relatedPlaceTable.snp.updateConstraints {
            $0.height.equalTo(relatedPlaceTableHeight)
        }
        
        relatedVerseTable.reloadData()
        relatedVerseTable.layoutIfNeeded();
        
        let relatedVerseTableHeight = relatedVerseTable.contentSize.height;
        
        relatedVerseTable.snp.updateConstraints {
            $0.height.equalTo(relatedVerseTableHeight)
        }
        
        
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.sheetPresentationController?.delegate = nil
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI();
        setupStyle();
        setupConstraints()
        setupSheet()
        bindViewModel();
        
        placeDetailViewLoaded$.accept(Void())
    }
    
    deinit {
        print("🔥 PlaceDetailVC deinit")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollUp();
    }

    
    private func setupUI(){
        view.addSubview(bodyView)
        view.addSubview(loadingView)
        view.addSubview(errorRetryView)
    }
    
    private func setupConstraints(){
        bodyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        subInfoStackView.snp.makeConstraints { make in
            make.top.equalTo(headerStackView.snp.bottom).offset(0);
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20);
        }
        
        likeAndMoreButtonsStackView.snp.makeConstraints { make in
            make.top.equalTo(subInfoStackView.snp.bottom).offset(10);
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20);
            make.height.equalTo(40)
        }
        
        
        avatarImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        placeImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        memoButton.snp.makeConstraints { make in
            make.top.equalTo(likeAndMoreButtonsStackView.snp.bottom).offset(20);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);
        }
        
        memoStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(15)
            make.bottom.equalToSuperview().offset(-15)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        userAvatarView.snp.makeConstraints { make in
            make.height.width.equalTo(40)
        }
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        headerStackView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);
        }
        
        filledCircleView.snp.makeConstraints { make in
            make.width.height.equalTo(5);
        }
        
        moreButton.snp.makeConstraints { make in
            make.width.equalTo(40)
        }
        
        imageButton.snp.makeConstraints { make in
            make.top.equalTo(memoButton.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-150);
            make.height.equalTo(300)
        }
    
        descriptionStackView.snp.makeConstraints { make in
            make.top.equalTo(imageButton.snp.bottom).offset(30)
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);
        }
        
        descriptionTextView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        relatedLocationStackView.snp.makeConstraints { make in
            make.top.equalTo(descriptionStackView.snp.bottom).offset(30)
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);
        }
        
        relatedVerseStackView.snp.makeConstraints { make in
            make.top.equalTo(relatedLocationStackView.snp.bottom).offset(30)
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);
        }
     
        reportIssueButton.snp.makeConstraints { make in
            make.top.equalTo(relatedVerseStackView.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);
            make.bottom.equalToSuperview().offset(-20)
            
        }
        
        

        
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        errorRetryView.snp.makeConstraints { make in
            make.centerY.equalToSuperview();
            make.trailing.leading.equalToSuperview()
        }
        
        relatedPlaceEmptyView.snp.makeConstraints { make in
            make.height.equalTo(80);
        }
        
        relatedPlaceEmptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        relatedVerseEmptyView.snp.makeConstraints { make in
            make.height.equalTo(80)
        }
        
        relatedVerseEmptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        likeLoadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func setupStyle(){
        view.backgroundColor = .mainBkg;
    }
    

    
    
    private func bindViewModel(){
        
        let saveButtonTapped$ = saveButton.rx.tap.asObservable();

        
        let closeButtonTapped$ = Observable.merge(
            closeButton.rx.tap.asObservable(),
            errorRetryView.closeTapped$.asObservable()
          );
        
        let likeButtonTapped$ = likeButton.rx.tap.asObservable();
        let backButtonTapped$ = backButton.rx.tap.asObservable();

        let refetchButtonTapped$ = errorRetryView.refetchTapped$;
        
        
        memoButton.rx.tap.subscribe(onNext: {[weak self] in
            self?.memoButtonTapped$.accept(Void())})
        .disposed(by: disposeBag)
        
        
        
        let output = placeDetailViewModel?.transform(input: PlaceDetailViewModel.Input(viewLoaded$: placeDetailViewLoaded$.asObservable(), saveButtonTapped$: saveButtonTapped$, closeButtonTapped$: closeButtonTapped$, backButtonTapped$: backButtonTapped$, likeButtonTapped$: likeButtonTapped$, placeModificationButtonTapped$: placeModificationButtonTapped$.asObservable(), verseButtonTapped$: verseCellTapped$.asObservable(), memoButtonTapped$: memoButtonTapped$.asObservable(), placeCellTapped$: placeCellTapped$.asObservable(), refetchButtonTapped$: refetchButtonTapped$.asObservable(), verseCellTapped$: verseCellTapped$.asObservable(), reportButtonTapped$: reportButtonTapped$.asObservable()))
        
        output?.isSaving$.observe(on: MainScheduler.instance).bind{
            [weak self] isSaving in
            if(isSaving){
                self?.saveButton.startLoading()
            }
            else{
                self?.saveButton.stopLoading()
            }
        }.disposed(by: disposeBag)
        
        
        Observable.combineLatest(output!.isLiking$, output!.place$)
            .observe(on: MainScheduler.instance)
            .bind{
                [weak self] isLiking, place in
                guard let place = place else {
                    return;
                }
                
                self?.scrollView.isScrollEnabled = false
                if(place.isLiked ?? false){
                    self?.likeButton.backgroundColor = .primaryBlue
                    self?.likeButton.setTitleColor(.white, for: .normal)
                    self?.likeButton.tintColor = .white
                }
                else{
                    self?.likeButton.backgroundColor = .circleButtonBkg
                    self?.likeButton.setTitleColor(.mainText, for: .normal)
                    self?.likeButton.tintColor = .mainText
                }
                
                
                if(isLiking){
                    self?.likeButton.setTitle(nil, for: .normal)
                    self?.likeButton.isEnabled = false;
                    self?.likeLoadingView.start()
                    self?.likeButton.setImage(nil, for: .normal)
                    
                }
                else{
                    self?.likeButton.setTitle("\(place.likeCount) Likes", for: .normal)
                    self?.likeButton.isEnabled = true;
                    self?.likeLoadingView.stop()
                    let image = UIImage(systemName: "hand.thumbsup.fill")
                    self?.likeButton.setImage(image, for: .normal)
                }

                
                
            }.disposed(by: disposeBag)
        
        output?.profile$.observe(on: MainScheduler.instance).bind{
            [weak self] profile in
            guard let profile = profile else { return }
            self?.setAvatarImage(urlString: profile.avatar)
        }.disposed(by: disposeBag)

    
        output?.place$.observe(on: MainScheduler.instance).bind{
            [weak self] place in
            
            guard let self = self else { return }
            
            guard let place = place else { return }
            
            self.sheetPresentationController?.animateChanges {
                self.sheetPresentationController?.selectedDetentIdentifier = .medium
            }
            
            self.titleLabel.text = place.name
            self.descriptionTextView.text = place.koreanDescription
            
                
            self.generationLabel.text = place.isModern ? "modern" : "ancient"
            
            let childRelations = place.childRelations ?? []
            let parentRelations = place.parentRelations ?? []

            self.relations = childRelations + parentRelations;
            
            if(self.relations.count == 0) {
                self.relatedPlaceTable.isHidden = true;
                self.relatedPlaceEmptyView.isHidden = false;
            }
            
            
            self.setPlaceImage(imageTitle: place.imageTitle)
            
            self.saveButton.setActive(isActive: place.isSaved ?? false)
            
            
      
            
            guard let placeType = place.types.first else { return }
         
            self.placeTypeButton.setTitle("\(placeType.name.rawValue)", for: .normal)
            
        }.disposed(by:disposeBag)
        
        
        output?.bibles$.observe(on: MainScheduler.instance).bind{
            [weak self] bibles in
            self?.bibles = bibles;
            self?.relatedVerseTable.isHidden = bibles.isEmpty;
            self?.relatedVerseEmptyView.isHidden = !bibles.isEmpty;
            
            
            
        }.disposed(by: disposeBag)
        
        Observable.combineLatest(output!.isLoggedIn$ , output!.place$)
            .observe(on: MainScheduler.instance).bind{
            [weak self] isLoggedIn, place in
            guard let place = place else {return}

            if(isLoggedIn && place.memo != nil){
                self?.memoLabel.text = place.memo?.text
                self?.showMemoButton()
            }
            else{
                self?.hideMemoButton()
            }
            
        }.disposed(by: disposeBag)
                                 
        Observable.combineLatest(output!.isLoading$, output!.loadError$)
            .observe(on: MainScheduler.instance)
            .bind{ [weak self] isLoading, error in
                guard let self = self else { return }
            
                
                if let error = error {
                    switch(error){
                        default:
                        self.errorRetryView.setMessage(error.description);
                        self.bodyView.isHidden = true;
                        self.loadingView.isHidden = true;
                        self.errorRetryView.isHidden = false;
                    }
                    return
                }
                if isLoading{
                    self.loadingView.start();
                    self.bodyView.isHidden = true;
                    self.errorRetryView.isHidden = true;
                    return;
                }
                
                
                self.loadingView.stop();
                self.bodyView.isHidden = false;
            }
            .disposed(by: disposeBag)
        
        
        output?.interactionError$
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: {[weak self] error in
                guard let error = error else{
                    return;
                }
                self?.showAlert(message: error.description)
            })
            .disposed(by: disposeBag)
        
        
        output?.hasPrevPlaceId$.observe(on: MainScheduler.instance)
            .bind{ [weak self] hasPrevPlaceId in
                self?.backButton.isHidden = !hasPrevPlaceId
            }
            .disposed(by: disposeBag)

        
    }
    
    
    private func showAlert(message: String?) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    private func buildMoreMenu() -> UIMenu {
        let action1 = UIAction(title: "Add Memo", image: UIImage(systemName: "note.text.badge.plus")) { [weak self] _ in
            
            self?.memoButtonTapped$.accept(Void())
        }

        let action2 = UIAction(title: "Request Modification", image: UIImage(systemName: "pencil.and.scribble")) { [weak self ]_ in
            self?.placeModificationButtonTapped$.accept(Void())
        }

        // 신고 타입별 submenu actions
        let reportActions: [UIAction] = [
            UIAction(title: "Spam", image: UIImage(systemName: "exclamationmark.circle")) { [weak self] _ in
                self?.reportButtonTapped$.accept(.spam)
            },
            UIAction(title: "Inappropriate", image: UIImage(systemName: "hand.raised")) { [weak self] _ in
                self?.reportButtonTapped$.accept(.inappropriate)
            },
            UIAction(title: "False Information", image: UIImage(systemName: "questionmark.diamond")) { [weak self] _ in      self?.reportButtonTapped$.accept(.falseInfomation) },
            UIAction(title: "Other", image: UIImage(systemName: "ellipsis")) { [weak self] _  in
                self?.reportButtonTapped$.accept(.etc)
            }
        ]

        // nested 메뉴
        let reportMenu = UIMenu(
            title: "Report Issue",
            image: UIImage(systemName: "exclamationmark.bubble"),
            options: .displayInline,
            children: reportActions
        )

        return UIMenu(title: "", children: [action1, action2, reportMenu])
    }
    
    
    private func buildIssueReportMenu() -> UIMenu {
        let reportActions: [UIAction] = [
            UIAction(title: "Spam", image: UIImage(systemName: "exclamationmark.circle")) { _ in print("Report: SPAM") },
            UIAction(title: "Inappropriate", image: UIImage(systemName: "hand.raised")) { _ in print("Report: INAPPROPRIATE") },
            UIAction(title: "False Information", image: UIImage(systemName: "questionmark.diamond")) { _ in print("Report: FALSE_INFORMATION") },
            UIAction(title: "Other", image: UIImage(systemName: "ellipsis")) { _ in print("Report: ETC") }
        ]
        
        return UIMenu(title: "", children: reportActions)

    }
    
    private func hideMemoButton(){
        memoButton.isHidden = true;
        imageButton.snp.remakeConstraints { make in
            make.top.equalTo(likeAndMoreButtonsStackView.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-150);
            make.height.equalTo(300)
        }
    }
    
    private func showMemoButton(){
        memoButton.isHidden = false;
        imageButton.snp.remakeConstraints { make in
            make.top.equalTo(memoButton.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-150);
            make.height.equalTo(300)
        }
        
    }
    
    
    @objc private func showShareVC() {
        guard let place = placeDetailViewModel?.currentPlace else { return }

        let type = place.types.first
        let image = UIImage(named: type?.name.rawValue ?? "ground")

        let shareURL = URL(string: "https://bibleatlas.app/places/\(place.id)")!

        let source = ShareItemSourceView(
            url: shareURL,
            title: place.name,
            image: image
        )

        let activityVC = UIActivityViewController(activityItems: [source], applicationActivities: nil)
        present(activityVC, animated: true)
    }
    
    
    
}


extension PlaceDetailViewController:UISheetPresentationControllerDelegate{
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
          let isLarge = sheetPresentationController.selectedDetentIdentifier == .large
          scrollView.isScrollEnabled = isLarge
      }
}



extension PlaceDetailViewController:UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == relatedPlaceTable {
              return relations.count
          } else if tableView == relatedVerseTable {
              return bibles.count
          }
          return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if(tableView == relatedPlaceTable){
            guard let cell = tableView.dequeueReusableCell(withIdentifier: RelatedPlaceTableViewCell.identifier, for: indexPath) as? RelatedPlaceTableViewCell else {
                return UITableViewCell()
            }
            
            cell.setRelation(relation: relations[indexPath.row])

            if indexPath.row == relations.count - 1 {
                   cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.width, bottom: 0, right: 0)
               } else {
                   cell.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
            }
            
            
            return cell
            
        }
        
        else if (tableView == relatedVerseTable){
            guard let cell = tableView.dequeueReusableCell(withIdentifier: RelatedVerseTableViewCell.identifier, for: indexPath) as? RelatedVerseTableViewCell else {
                return UITableViewCell()
            }
            
            let bible = bibles[indexPath.row];
            
            
            cell.configure(with: bible.verses, title: bible.bookName)

            cell.delegate = self;
            if indexPath.row == bibles.count - 1 {
                   cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.width, bottom: 0, right: 0)
               } else {
                   cell.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
            }
            
            
            return cell
            
            
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            if tableView == relatedPlaceTable {
                let selectedRelation = relations[indexPath.row]
                placeCellTapped$.accept(selectedRelation.place.id)
                scrollView.isScrollEnabled = false;
                scrollUp();
                
            } else if tableView == relatedVerseTable {
                // 선택해도 별도 처리가 없다면 비워둬도 OK
            }
        }
    
    
}

extension PlaceDetailViewController: RelatedVerseTableViewCellDelegate {
    func didTapVerse(_ verse: String, in cell: RelatedVerseTableViewCell) {
        verseCellTapped$.accept(verse)
    }
}


extension PlaceDetailViewController: IdentifiableBottomSheet {
    var bottomSheetIdentity: BottomSheetType {
        .placeDetail(self.placeId)
    }
}



#if DEBUG

extension PlaceDetailViewController {
    // 읽기 전용 상태/뷰 확인용
    var _test_isBodyHidden: Bool { bodyView.isHidden }
    var _test_isLoadingVisible: Bool { !loadingView.isHidden && loadingView.isAnimating }
    var _test_isErrorVisible: Bool { !errorRetryView.isHidden }

    var _test_isRelatedPlaceTableVisible: Bool { !relatedPlaceTable.isHidden }
    var _test_isRelatedVerseTableVisible: Bool { !relatedVerseTable.isHidden }
    var _test_isRelatedVerseEmptyViewVisible: Bool { !relatedVerseEmptyView.isHidden }

    var _test_isLikeLoadingVisible: Bool { !likeLoadingView.isHidden && likeLoadingView.isAnimating }

    
    var _test_titleText: String? { titleLabel.text }
    var _test_generationText: String? { generationLabel.text }
    var _test_descriptionText: String? { descriptionTextView.text }

    var _test_likeButtonTitle: String? { likeButton.title(for: .normal) }
    var _test_likeButtonEnabled: Bool { likeButton.isEnabled }
    var _test_likeButtonImage: UIImage? { likeButton.image(for: .normal)}
    var _test_likeButton:UIButton? {likeButton}
    
    var _test_saveButton:ToggleCircleButton? {saveButton}
    
    var _test_memoButton:UIButton? {memoButton}
    var _test_memoLabel:UILabel? {memoLabel}

    var _test_relatedPlaceCount: Int { relatedPlaceTable.numberOfRows(inSection: 0) }
    var _test_relatedVerseCount: Int { relatedVerseTable.numberOfRows(inSection: 0) }

    var _test_isScrollEnabled: Bool { scrollView.isScrollEnabled }
    
    // 사용자 상호작용 시뮬레이션
    func _test_tapClose() { closeButton.sendActions(for: .touchUpInside) }
    func _test_tapSave() { saveButton.sendActions(for: .touchUpInside) }
    func _test_tapLike() { likeButton.sendActions(for: .touchUpInside) }
    func _test_tapBack() { backButton.sendActions(for: .touchUpInside) }
    func _test_tapMemo() { memoButton.sendActions(for: .touchUpInside) }

    func _test_selectRelatedPlaceRow(_ row: Int) {
        let indexPath = IndexPath(row: row, section: 0)
        relatedPlaceTable.delegate?.tableView?(relatedPlaceTable, didSelectRowAt: indexPath)
    }

    func _test_selectRelatedVerseRow(_ row: Int) {
        let indexPath = IndexPath(row: row, section: 0)
        relatedVerseTable.delegate?.tableView?(relatedVerseTable, didSelectRowAt: indexPath)
    }
    
    func _test_makeVerseCell(row: Int) -> RelatedVerseTableViewCell? {
            let idx = IndexPath(row: row, section: 0)
            // dataSource 경유로 VC의 cellForRowAt을 타서 delegate가 VC로 세팅됨
            return relatedVerseTable.dataSource?
                .tableView(relatedVerseTable, cellForRowAt: idx) as? RelatedVerseTableViewCell
    }
    
    
}
#endif
