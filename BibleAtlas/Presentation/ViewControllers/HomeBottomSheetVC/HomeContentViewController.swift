//
//  HomeContentViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 6/21/25.
//

import UIKit
import RxSwift
import RxCocoa


final class HomeContentViewController: UIViewController {

    private var homeContentViewModel:HomeContentViewModelProtocol?
    
    private let placesByTypeButtonTapped$ = PublishRelay<Void>();
    
    private let placesByCharacterButtonTapped$ = PublishRelay<Void>();
    
    
    private let disposeBag = DisposeBag()

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
    
    private let loadingView = LoadingView();

    
    private lazy var contentView = {
        let v = UIView()
        v.addSubview(collectionStackView);
        v.addSubview(recentStackView);
        v.addSubview(myGuidesStackView)
        return v
    }()
    
    private lazy var collectionStackView = {
        let sv = UIStackView(arrangedSubviews: [collectionLabel, collectionDynamicContainer]);
        sv.axis = .vertical;
        sv.distribution = .fill;
        sv.alignment = .fill
        sv.spacing = 10;
        return sv;
    }();
    
    private let collectionLabel = MainLabel(text:"Collections")
    
    private lazy var collectionDynamicContainer = {
        let sv = UIStackView(arrangedSubviews: [collectionContentStackView])
        sv.axis = .vertical
           sv.alignment = .fill
           sv.distribution = .fill
           return sv
    }()
    
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
        let sv = UIStackView(arrangedSubviews: [recentLabel]);
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
    
    init(homeContentViewModel: HomeContentViewModelProtocol) {
        self.homeContentViewModel = homeContentViewModel

        super.init(nibName: nil, bundle: nil)
    }
    
    
    init(){
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI();
        setupStyle();
        setupConstraints();
        bindViewModel();
        print("home content vc")
    }
    
    private func setupUI(){
        view.addSubview(bodyView);
        view.addSubview(loadingView);
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
    
    
    private func setupStyle(){
        view.backgroundColor = .mainBkg;
    }
    
    
    private func setupConstraints(){
        bodyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        
        contentView.snp.makeConstraints { make in
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
       
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview();
        }
    }
    
    private func bindViewModel(){

        
        let favoriteTapped$ = favoriteButton.rx.tap.map { PlaceFilter.like }
        let bookmarkTapped$ = bookmarkButton.rx.tap.map { PlaceFilter.save }
        let memoTapped$ = memoButton.rx.tap.map { PlaceFilter.memo }

        let collectionButtonTapped$ = Observable.merge(favoriteTapped$, bookmarkTapped$, memoTapped$)
        
        let output = homeContentViewModel?.transform(input: HomeContentViewModel.Input(collectionButtonTapped$: collectionButtonTapped$.asObservable(), placesByTypeButtonTapped$: placesByTypeButtonTapped$.asObservable(), placesByCharacterButtonTapped$: placesByCharacterButtonTapped$.asObservable()))
        
        
        

        

        Observable.combineLatest(output!.likePlacesCount$,output!.savePlacesCount$, output!.memoPlacesCount$).observe(on: MainScheduler.instance).subscribe { (likePlacesCount, savePlacesCount, memoPlacesCount) in
            self.favoriteButton.setSubLabelText(subText: "\(likePlacesCount) places")
            self.bookmarkButton.setSubLabelText(subText: "\(savePlacesCount) places")
            self.memoButton.setSubLabelText(subText: "\(memoPlacesCount) places")
            
        }.disposed(by: disposeBag)
        
        output?.loading$.observe(on: MainScheduler.instance)
            .subscribe(onNext: { loading in
                if(loading){
                    self.scrollView.isHidden = true;
                    self.loadingView.start();
                }
                else{
                    self.scrollView.isHidden = false;
                    self.loadingView.stop();
                }
            }).disposed(by: disposeBag)
    
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
    
}


extension HomeContentViewController:UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dummySearches.count
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
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
}
