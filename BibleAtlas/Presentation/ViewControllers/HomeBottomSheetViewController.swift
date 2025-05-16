//
//  HomeBottomSheetViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/19/25.
//

import UIKit
import RxSwift
import RxCocoa
final class HomeBottomSheetViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    private var homeBottomSheetViewModel:HomeBottomSheetViewModelProtocol?
    
    private let placesByTypeButtonTapped$ = PublishRelay<Void>();
    private let placesByCharacterButtonTapped$ = PublishRelay<Void>();
    
    private lazy var bodyView = {
        let v = UIView();
        v.addSubview(headerStackView);
        v.addSubview(scrollView);
        view.addSubview(v);
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
        v.addSubview(collectionStackView);
        v.addSubview(recentStackView);
        v.addSubview(myGuidesStackView)
        return v
    }()
    
    
    private lazy var headerStackView = {
        let sv = UIStackView(arrangedSubviews: [searchTextField, userAvatarButton]);
        
        sv.axis = .horizontal;
        sv.spacing = 10;
        sv.distribution = .fill;
        sv.alignment = .fill;
        
        return sv;
    }()
    
    private lazy var searchTextField: UISearchTextField = {
        let input = UISearchTextField()
        
        
        input.placeholder = "search places..."
        
        input.font = .systemFont(ofSize: 16)
        
        input.returnKeyType = .search
        
        
        return input
    }()
    
    
    
    private lazy var userAvatarButton = {
        let button = UIButton(type: .system)
        
        button.backgroundColor = .userAvatarBkg;
        button.layer.cornerRadius = 20;
        button.layer.masksToBounds = true;
        button.setTitle("로그인", for: .normal)
        
        button.setTitleColor(.primaryBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
 
        
        return button;
    }()
    
    private lazy var collectionStackView = {
        let sv = UIStackView(arrangedSubviews: [collectionLabel, collectionContentStackView]);
        sv.axis = .vertical;
        sv.distribution = .fill;
        sv.alignment = .fill
        sv.spacing = 10;
        return sv;
    }();
    
    private let collectionLabel = MainLabel(text:"Collections")
    
    private lazy var collectionContentStackView = {
        let sv = UIStackView(arrangedSubviews: [favoriteButton, bookmarkButton, memoButton]);
        sv.axis = .horizontal;
        sv.distribution = .fillEqually;
        sv.alignment = .fill;
        sv.backgroundColor = .mainItemBkg;
        sv.isLayoutMarginsRelativeArrangement = true
        sv.layoutMargins = UIEdgeInsets(top: 30, left: 0, bottom: 30, right: 0)
        sv.layer.cornerRadius = 10;
        sv.layer.masksToBounds = true;
        return sv;
    }()
    
    private lazy var favoriteButton = {
        let button = CollectionButton(
            iconSystemName: "hand.thumbsup.fill",
            mainText: "Favorites",
            subText: "0 places"
        )
        
        return button;
    }()
    
    private lazy var bookmarkButton = {
        let button = CollectionButton(
            iconSystemName: "bookmark.fill",
            mainText: "Bookmarks",
            subText: "0 places"
        );
        return button;
    }()
    
    private lazy var memoButton = {
        let button = CollectionButton(
            iconSystemName: "note.text",
            mainText: "Memos",
            subText: "0 places"
        );
        return button;
    }()
    
    
    private lazy var recentStackView = {
        let sv = UIStackView(arrangedSubviews: [recentLabel,]);
        sv.axis = .vertical;
        sv.distribution = .fill;
        sv.alignment = .fill
        sv.spacing = 10;
        return sv;
    }();
        
    private lazy var recentSearchTableView: UITableView = {
        let tv = UITableView()
        tv.register(RecentSearchTableViewCell.self, forCellReuseIdentifier: RecentSearchTableViewCell.identifier)
        tv.delegate = self
        tv.dataSource = self
        tv.isScrollEnabled = false
        tv.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)


        tv.backgroundColor = .mainItemBkg
        tv.layer.cornerRadius = 10;
        tv.layer.masksToBounds = true;
        tv.rowHeight = 80
        return tv
    }()

    private let recentLabel = MainLabel(text:"Recent")
    
    
    private lazy var myGuidesStackView = {
        let sv = UIStackView(arrangedSubviews: [myGuidesLabel, guideButtonsStackView]);
        sv.axis = .vertical;
        sv.distribution = .fill;
        sv.alignment = .fill
        sv.spacing = 10;
        return sv;
    }();
    
    private let myGuidesLabel = MainLabel(text:"My Guides")
    
    private lazy var guideButtonsStackView = {
        let sv = UIStackView(arrangedSubviews: [explorePlacesButton, reportIssueButton]);
        sv.axis = .vertical;
        sv.distribution = .fill;
        sv.alignment = .fill
        sv.spacing = 8;
        return sv;
    }()
    
    private let explorePlacesButton = {
        let button = GuideButton(titleText: "Explore Places")
        button.addTarget(self, action: #selector(explorePlacesBtnTapped), for: .touchUpInside)
        return button;
    }()
    
    private let reportIssueButton =  {
        let button = GuideButton(titleText: "Report an Issue");
        button.addTarget(self, action: #selector(reportIssueBtnTapped), for: .touchUpInside)
        return button;
    }()
    

    
    private let dummySearches:[String] = ["onasdasdasdasdasddfasdfdfasdfasdfasdfasdfasdfe", "sdfasdfadsfasdfasdffsdsadf"];
    
    init(){
        super.init(nibName: nil, bundle: nil)
    }
    
    
 

   
    private func bindViewModel(){
        let avatarButtonTapped$ = userAvatarButton.rx.tap.asObservable();
        
        let favoriteTapped$ = favoriteButton.rx.tap.map { MyCollectionType.favorite }
        let bookmarkTapped$ = bookmarkButton.rx.tap.map { MyCollectionType.save }
        let memoTapped$ = memoButton.rx.tap.map { MyCollectionType.memo }

        let collectionButtonTapped$ = Observable.merge(favoriteTapped$, bookmarkTapped$, memoTapped$)
        
        homeBottomSheetViewModel?.transform(input: HomeBottomSheetViewModel.Input(avatarButtonTapped$: avatarButtonTapped$, collectionButtonTapped$: collectionButtonTapped$, placesByTypeButtonTapped$: placesByTypeButtonTapped$.asObservable(), placesByCharacterButtonTapped$: placesByCharacterButtonTapped$.asObservable()) )
    }
    
    


    
    @objc private func explorePlacesBtnTapped(){

        let action1 = UIAction(title: "A-Z", image: UIImage(systemName: "character.phonetic")) { _ in
            self.placesByCharacterButtonTapped$.accept(Void())
        }
        let action2 = UIAction(title: "By Type", image: UIImage(systemName: "mappin.and.ellipse")) { _ in
            self.placesByTypeButtonTapped$.accept(Void())

        }
               
        let menu = UIMenu(title: "Explore Places", children: [action1, action2])
        
        explorePlacesButton.showsMenuAsPrimaryAction = true
        explorePlacesButton.menu = menu

    }
    
    
    @objc private func reportIssueBtnTapped(){

        let action1 = UIAction(title: "Spam", image: UIImage(systemName: "exclamationmark.bubble.fill")) { _ in
            print("A-Z")
        }

        let action2 = UIAction(title: "Inappropriate", image: UIImage(systemName: "hand.raised.fill")) { _ in
            print("By Type")
        }
               
        let menu = UIMenu(title: "Report Issue", children: [action1, action2])
        
        reportIssueButton.showsMenuAsPrimaryAction = true
        reportIssueButton.menu = menu

    }
    
    
    init(homeBottomSheetViewModel:HomeBottomSheetViewModelProtocol) {
        self.homeBottomSheetViewModel = homeBottomSheetViewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        recentSearchTableView.reloadData()
        recentSearchTableView.layoutIfNeeded()

        let height = recentSearchTableView.contentSize.height
        recentSearchTableView.snp.updateConstraints {
            $0.height.equalTo(height)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupStyle();
        setupConstraints();
        setupSheet();
        bindViewModel();
        
    }

    
    private func setupSheet(){
        if let sheet = self.sheetPresentationController {
            sheet.delegate = self
        }
    }
    
    
    
    private func setupStyle(){
        view.backgroundColor = .mainBkg;
    }
    
    private func setupConstraints(){
        bodyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        
        headerStackView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);
            make.height.equalTo(40);
        }
        
        userAvatarButton.snp.makeConstraints { make in
            make.width.equalTo(40);
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(headerStackView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        
        collectionStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(30);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);
        }
        
        recentStackView.snp.makeConstraints { make in
            make.top.equalTo(collectionStackView.snp.bottom).offset(30);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);
        }
        
        myGuidesStackView.snp.makeConstraints { make in
            make.top.equalTo(recentStackView.snp.bottom).offset(30);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);
            make.bottom.equalToSuperview().offset(-30)

        }
        
        recentStackView.addArrangedSubview(recentSearchTableView)

        explorePlacesButton.snp.makeConstraints { make in
            make.height.equalTo(64)
        }
        
        reportIssueButton.snp.makeConstraints { make in
            make.height.equalTo(64)
        }
       
        
    }
    

    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dummySearches.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RecentSearchTableViewCell.identifier, for: indexPath) as? RecentSearchTableViewCell else {
            return UITableViewCell()
        }

        cell.setText(text: dummySearches[indexPath.row])
        
        if indexPath.row == dummySearches.count - 1 {
               cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.width, bottom: 0, right: 0)
           } else {
               cell.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        }
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80;
    }
}


extension HomeBottomSheetViewController:UISheetPresentationControllerDelegate{
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
          let isLarge = sheetPresentationController.selectedDetentIdentifier == .large
          scrollView.isScrollEnabled = isLarge
      }
}
