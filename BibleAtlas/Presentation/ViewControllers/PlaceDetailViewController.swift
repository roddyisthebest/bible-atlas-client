//
//  PlaceDetailViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/3/25.
//

import UIKit
import RxSwift
import RxRelay

final class Bible {
    var verses:[String] = []
    var bookName:String = "창세기"
    init(bookName:String, verses:[String]){
        self.bookName = bookName
        self.verses = verses;
    }
}

class PlaceDetailViewController: UIViewController {
    
    private var placeDetailViewModel:PlaceDetailViewModelProtocol?
    
    private let disposeBag = DisposeBag();

    private let dummyPlaces:[String] = ["onasf", "sdfasdfadsfasdfasddasdasdsadasdasdadsffsdsadf","ffeqfdasdsqssdqwddsas"];
        
    private let dummyVerse:[Bible] = [ Bible(bookName:"창세기", verses: ["12:23","12:24"]), Bible(bookName:"출애굽기", verses: ["11:23","11:24","11:23","11:24","11:23","11:24","11:23","11:24","11:23","11:24","11:23","11:24","11:23","11:24","11:23","11:24","11:23","11:24","11:23","11:24","11:23","11:24","11:23","11:24"])]
    
    private let placeDetailViewLoaded$ = PublishRelay<Void>();
    
    private lazy var bodyView = {
        let v = UIView();
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
    
    private let saveButton = CircleButton(iconSystemName:"bookmark")
    
    private let shareButton = CircleButton(iconSystemName: "square.and.arrow.up")
    
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
   
    private let likeButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "hand.thumbsup.fill")
        
        button.setImage(image, for: .normal)
        button.setTitle("7 Likes", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.tintColor = .white
        button.backgroundColor = .primaryBlue
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .center // 왼쪽 정렬 필요 시
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        button.layer.cornerRadius = 8;
        button.layer.masksToBounds = true;
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
    
    private let imageButton = {
        let button = UIButton(type:.system);
        let image = UIImage()
        
        button.setImage(image, for: .normal);
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
        let sv = UIStackView(arrangedSubviews: [relatedLocationLabel, relatedPlaceTable]);
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
    
    private lazy var memoButton:UIButton = {
        let button = UIButton(type:.system);
        button.backgroundColor = .mainItemBkg
        button.addSubview(memoStackView)
        button.layer.cornerRadius = 8;
        button.layer.masksToBounds = true
        return button;
    }()
    
    private lazy var memoStackView:UIStackView = {
        let sv = UIStackView(arrangedSubviews: [userAvatarView, memoTextView] );
        sv.axis = .horizontal
        sv.distribution = .fill;
        sv.alignment = .center;
        sv.spacing = 10;
        return sv;
    }()
    
    private let userAvatarView = {
        let v = UIView()
        
        v.backgroundColor = .userAvatarBkg;
        v.layer.cornerRadius = 20;
        v.layer.masksToBounds = true;
        
        return v
    }()
    
    private let memoTextView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = .clear // ✅ 배경 투명 (필요에 따라 변경 가능)
        tv.textColor = .mainText
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.isScrollEnabled = false
        tv.isEditable = false
        tv.isSelectable = false
        tv.text = "인사까지 연습했는데 거기까진 문제없었는데 니 앞에서면"

        return tv
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
        let button = UIButton(type:.system);
        button.addSubview(reportIssueButtonStackView)
        button.backgroundColor = .mainItemBkg
        button.layer.cornerRadius = 8;
        button.layer.masksToBounds = true;
        button.menu = buildIssueReportMenu();
        button.showsMenuAsPrimaryAction = true
        return button;
    }()
    
    
    private lazy var reportIssueButtonStackView = {
        let sv = UIStackView(arrangedSubviews: [reportIssueIcon, reportIssueLabel]);
        sv.axis = .horizontal
        sv.distribution = .fill;
        sv.alignment = .center;
        sv.spacing = 10;
        return sv;
    }()
    
    private lazy var reportIssueIcon = {
        let v = UIView()
        v.backgroundColor = .collectionCircle
        v.layer.cornerRadius = 15
        v.layer.masksToBounds = true

        let iv = UIImageView()
        iv.image = UIImage(systemName: "exclamationmark.bubble.fill")
        iv.tintColor = .primaryBlue
        iv.contentMode = .scaleAspectFit
        
        v.addSubview(iv);

        iv.snp.makeConstraints { make in
            make.width.height.equalTo(15)
            make.center.equalToSuperview()
        }
        
        
        return v;
    }()
    
    private lazy var reportIssueLabel = {
        let label = UILabel();
        label.text = "Report an issue"
        label.font = .systemFont(ofSize: 15, weight: .semibold);
        label.textColor = .primaryBlue;
        return label;
    }()
    
    private lazy var relatedVerseStackView = {
        let sv = UIStackView(arrangedSubviews: [relatedVerseLabel, relatedVerseTable]);
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
    
    init(placeDetailViewModel:PlaceDetailViewModelProtocol) {
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI();
        setupStyle();
        setupConstraints()
        setupSheet()
        bindViewModel();
        placeDetailViewLoaded$.accept(Void())
    }
    
    private func setupUI(){
        view.addSubview(bodyView)
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
    
        reportIssueButtonStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(15);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
            make.bottom.equalToSuperview().inset(15);
        }
        
        reportIssueIcon.snp.makeConstraints { make in
            make.width.height.equalTo(30) // 아이콘 사이즈
        }
       
        
    }
    
    private func setupStyle(){
        view.backgroundColor = .mainBkg;
    }
    
    private func bindViewModel(){
        
        let saveButtonTapped$ = saveButton.rx.tap.asObservable();
        let shareButtonTapped$ = shareButton.rx.tap.asObservable();
        let closeButtonTapped$ = closeButton.rx.tap.asObservable();
        
        let likeButtonTapped$ = likeButton.rx.tap.asObservable();
        
    
        let output = placeDetailViewModel?.transform(input: PlaceDetailViewModel.Input(placeDetailViewLoaded$: placeDetailViewLoaded$.asObservable(), saveButtonTapped$: saveButtonTapped$, shareButtonTapped$: shareButtonTapped$, closeButtonTapped$: closeButtonTapped$, likeButtonTapped$: likeButtonTapped$));
    
        output?.placeData$.observe(on: MainScheduler.instance).bind{
            [weak self] data in
        }.disposed(by:disposeBag)
                                                    
        
    }
    
    private func buildMoreMenu() -> UIMenu {
        let action1 = UIAction(title: "Add Memo", image: UIImage(systemName: "note.text.badge.plus")) { _ in
            print("Add Memo")
        }

        let action2 = UIAction(title: "Request Modification", image: UIImage(systemName: "pencil.and.scribble")) { _ in
            print("Request Modification")
        }

        // 신고 타입별 submenu actions
        let reportActions: [UIAction] = [
            UIAction(title: "Spam", image: UIImage(systemName: "exclamationmark.circle")) { _ in print("Report: SPAM") },
            UIAction(title: "Inappropriate", image: UIImage(systemName: "hand.raised")) { _ in print("Report: INAPPROPRIATE") },
            UIAction(title: "False Information", image: UIImage(systemName: "questionmark.diamond")) { _ in print("Report: FALSE_INFORMATION") },
            UIAction(title: "Other", image: UIImage(systemName: "ellipsis")) { _ in print("Report: ETC") }
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
              return dummyPlaces.count
          } else if tableView == relatedVerseTable {
              return dummyVerse.count
          }
          return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if(tableView == relatedPlaceTable){
            guard let cell = tableView.dequeueReusableCell(withIdentifier: RelatedPlaceTableViewCell.identifier, for: indexPath) as? RelatedPlaceTableViewCell else {
                return UITableViewCell()
            }

            cell.setText(text: dummyPlaces[indexPath.row])

            if indexPath.row == dummyPlaces.count - 1 {
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
            
            let bible = dummyVerse[indexPath.row];
            
            
            cell.configure(with: bible.verses, title: bible.bookName)

            cell.delegate = self;
            if indexPath.row == dummyVerse.count - 1 {
                   cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.width, bottom: 0, right: 0)
               } else {
                   cell.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
            }
            
            
            return cell
            
            
        }
        
        return UITableViewCell()
    }
    

    
    
}

extension PlaceDetailViewController: RelatedVerseTableViewCellDelegate {
    func didTapVerse(_ verse: String, in cell: RelatedVerseTableViewCell) {
        print("Tapped verse:", verse)
    }
}
