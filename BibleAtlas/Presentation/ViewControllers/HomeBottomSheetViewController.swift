//
//  HomeBottomSheetViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/19/25.
//

import UIKit
import RxSwift
import RxCocoa

final class HomeBottomSheetViewController: UIViewController{
    
    private var homeBottomSheetViewModel:HomeBottomSheetViewModelProtocol?
    private var searchBottomSheetViewModel:SearchBottomSheetViewModelProtocol?
    
    private let placesByTypeButtonTapped$ = PublishRelay<Void>();
    private let placesByCharacterButtonTapped$ = PublishRelay<Void>();
        
    private let bottomReached$ = PublishRelay<Void>();

    private let placeCellSelected$ = PublishRelay<String>();
    
    private let disposeBag = DisposeBag()
    
    private lazy var bodyView = {
        let v = UIView();
        v.addSubview(headerStackView);
        v.addSubview(homeScrollView);
        v.addSubview(searchReadyView);
        v.addSubview(searchTableView);
        
            
        v.addSubview(searchingView);
        
        return v;
    }()
    
    private lazy var searchTableView = {
        let tv = UITableView();
        tv.register(PlaceTableViewCell.self, forCellReuseIdentifier: PlaceTableViewCell.identifier)
        
        tv.delegate = self;
        tv.dataSource = self;
        
        tv.backgroundColor = .mainItemBkg
        
        tv.layer.cornerRadius = 10;
        tv.layer.masksToBounds = true;
        tv.rowHeight = 80;
        
        tv.tableFooterView = footerLoadingView
        tv.isHidden = true;
        footerLoadingView.frame = CGRect(x: 0, y: 0, width: tv.bounds.width, height: 44)
        
        return tv;
    }()
    
    
    private let searchingView = LoadingView();
    private let footerLoadingView = LoadingView(style: .medium);

    
    private let searchReadyView = {
        let v = UIView();
        v.isHidden = true;
        v.backgroundColor = .yellow;
        return v;
    }()
    
    
    private lazy var homeScrollView = {
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
        let sv = UIStackView(arrangedSubviews: [searchTextField, userAvatarButton, cancelButton]);
        
        sv.axis = .horizontal;
        sv.spacing = 10;
        sv.distribution = .fill;
        sv.alignment = .fill;
        
        return sv;
    }()
    
    private lazy var searchTextField: UISearchTextField = {
        let input = UISearchTextField()
        
        input.delegate = self;
        input.placeholder = "search places..."
        
        input.font = .systemFont(ofSize: 16)
        
        input.returnKeyType =  .done
        
        input.autocorrectionType = .no
        input.spellCheckingType = .no
        input.translatesAutoresizingMaskIntoConstraints = false
        
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
    
    private let cancelButton = {
        let button =  UIButton(type: .system)
            
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.primaryBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)

        button.isHidden = true
        return button;
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
    
    private let loadingView: UIView = {
        let v = UIView()
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.startAnimating()
        v.addSubview(indicator)
        v.backgroundColor = .mainItemBkg;
        v.layer.cornerRadius = 10;
        v.layer.masksToBounds = true;
        v.snp.makeConstraints{ $0.height.equalTo(150)}
        indicator.snp.makeConstraints { $0.center.equalToSuperview() }
        return v
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
    
    
    private var places: [Place] = [];
    
    private let dummySearches:[String] = ["onasdasdasdasdasddfasdfdfasdfasdfasdfasdfasdfe", "sdfasdfadsfasdfasdffsdsadf"];
    
    
    private let lowDetent = UISheetPresentationController.Detent.custom { context in
        return UIScreen.main.bounds.height * 0.2;
    }
    
    
    init(){
        super.init(nibName: nil, bundle: nil)
    }
    
    private func setupUI(){
        view.addSubview(bodyView);
    }
    
    
    
    private func bindSearchViewModel(){
        let cancelButtonTapped$ = cancelButton.rx.tap.asObservable();
        let editingDidBegin$ = searchTextField.rx.controlEvent(.editingDidBegin).asObservable()

        let output = searchBottomSheetViewModel?.transform(input: SearchBottomSheetViewModel.Input( cancelButtonTapped$: cancelButtonTapped$, editingDidBegin$: editingDidBegin$, bottomReached$: bottomReached$.asObservable(), placeCellSelected$: placeCellSelected$.asObservable()))
        
        
        searchTextField.rx.text.orEmpty
            .subscribe(onNext: { output!.keywordRelay$.accept($0) })
            .disposed(by: disposeBag)
        
        
        output?.places$
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: {[weak self] places in
                self?.places = places
                self?.searchTableView.reloadData()
            })
            .disposed(by: disposeBag)
        
        
        output!.keywordText$
            .drive(searchTextField.rx.text)
            .disposed(by: disposeBag)
        
        
        output?.isSearchingMode$
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: {[weak self] isSearchingMode in
                guard let self = self, let sheet = self.sheetPresentationController else { return }
                     if isSearchingMode {
                         UIView.animate(withDuration: 0.3) {
                             sheet.animateChanges {
                                 sheet.selectedDetentIdentifier = .large
                             }
                            
                         }
                  
                         
                         sheet.detents = [.large()]
       
                         
                     } else {

                         sheet.detents = [.large(), .medium(), lowDetent]
                         
                         
                         self.searchTextField.resignFirstResponder()
                         UIView.animate(withDuration: 0.3) {
                             sheet.animateChanges {
                                 sheet.selectedDetentIdentifier = .medium
                             }
                         }
                         
                     }
                
            })
            .disposed(by: disposeBag)
        
        
        output?.screenMode$
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] mode in
                self?.homeScrollView.isHidden = (mode != .home)
                self?.searchReadyView.isHidden = (mode != .searchReady)
                self?.searchTableView.isHidden = (mode != .searching)
                
                if(mode == .home){
                    self?.userAvatarButton.isHidden = false;
                    self?.cancelButton.isHidden = true
                }
                else{
                    self?.userAvatarButton.isHidden = true;
                    self?.cancelButton.isHidden = false;
                }
            })
            .disposed(by: disposeBag)
        
        output?.isFetchingNext$
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: {[weak self] isFetchingNext in
                    
                if(isFetchingNext){
                    self?.footerLoadingView.start();
                }
                else{
                    self?.footerLoadingView.stop();
                }
            })
            .disposed(by: disposeBag)
        
        Observable.combineLatest(output!.isSearching$, output!.screenMode$)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isSearching, screenMode  in
                if(screenMode == .home || screenMode == .searchReady){
                    self?.searchTableView.isHidden = true;
                    self?.searchingView.stop()
                    return
                }
                
                
                if(isSearching){
                    self?.searchTableView.isHidden = true;
                    self?.searchingView.start()
                }
                else{
                    self?.searchTableView.isHidden = false;
                    self?.searchingView.stop()
                }
            })
            .disposed(by: disposeBag)
    }
    

   
    private func bindHomeViewModel(){
        let avatarButtonTapped$ = userAvatarButton.rx.tap.asObservable();
        
        let favoriteTapped$ = favoriteButton.rx.tap.map { PlaceFilter.like }
        let bookmarkTapped$ = bookmarkButton.rx.tap.map { PlaceFilter.save }
        let memoTapped$ = memoButton.rx.tap.map { PlaceFilter.memo }

        let collectionButtonTapped$ = Observable.merge(favoriteTapped$, bookmarkTapped$, memoTapped$)
        
        let output = homeBottomSheetViewModel?.transform(input: HomeBottomSheetViewModel.Input(avatarButtonTapped$: avatarButtonTapped$, collectionButtonTapped$: collectionButtonTapped$, placesByTypeButtonTapped$: placesByTypeButtonTapped$.asObservable(), placesByCharacterButtonTapped$: placesByCharacterButtonTapped$.asObservable()) )
        
        
        
        Observable
            .combineLatest(output!.isLoggedIn$, output!.profile$)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoggedIn, profile in
                
                if isLoggedIn {
                    
                    guard let profile = profile else {
                        return
                    }
                    self?.userAvatarButton.setTitle(profile.name ?? "shy", for: .normal)
                    return
                }
                
                self?.userAvatarButton.setTitle("로그인", for: .normal)
                
            })
            .disposed(by: disposeBag)

        Observable.combineLatest(output!.likePlacesCount$,output!.savePlacesCount$, output!.memoPlacesCount$).observe(on: MainScheduler.instance).subscribe { (likePlacesCount, savePlacesCount, memoPlacesCount) in
            self.favoriteButton.setSubLabelText(subText: "\(likePlacesCount) places")
            self.bookmarkButton.setSubLabelText(subText: "\(savePlacesCount) places")
            self.memoButton.setSubLabelText(subText: "\(memoPlacesCount) places")
            
        }.disposed(by: disposeBag)
        
        output?.loading$.observe(on: MainScheduler.instance)
            .subscribe(onNext: { loading in
                self.showLoadingView(loading)
            }).disposed(by: disposeBag)
    
        
        
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
    
    private func showLoadingView(_ isLoading: Bool) {
        collectionDynamicContainer.arrangedSubviews.forEach {
            collectionDynamicContainer.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        if isLoading {
            collectionDynamicContainer.addArrangedSubview(loadingView)
        } else {
            collectionDynamicContainer.addArrangedSubview(collectionContentStackView)
        }
    }
    
    
    init(homeBottomSheetViewModel: HomeBottomSheetViewModelProtocol, searchBottomSheetViewModel: SearchBottomSheetViewModelProtocol) {
        self.homeBottomSheetViewModel = homeBottomSheetViewModel
        self.searchBottomSheetViewModel = searchBottomSheetViewModel
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
        setupUI();
        setupStyle();
        setupConstraints();
        setupSheet();
        bindHomeViewModel();
        bindSearchViewModel();
        setupDismissKeyboardOnTap();
    }
    

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("home 없어짐")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("home 나타남")
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
        
        
        
        
        searchReadyView.snp.makeConstraints { make in
            make.top.equalTo(headerStackView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        searchingView.snp.makeConstraints { make in
            make.top.equalTo(headerStackView.snp.bottom).offset(20);
            make.leading.equalToSuperview().offset(20)
            make.trailing.bottom.equalToSuperview().inset(20);
        }
        
        searchTableView.snp.makeConstraints { make in
            make.top.equalTo(headerStackView.snp.bottom).offset(20);
            make.leading.equalToSuperview().offset(20)
            make.trailing.bottom.equalToSuperview().inset(20);
        }
        
        homeScrollView.snp.makeConstraints { make in
            make.top.equalTo(headerStackView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(homeScrollView.contentLayoutGuide)
            make.width.equalTo(homeScrollView.frameLayoutGuide)
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
    

    
    
    
    

}


extension HomeBottomSheetViewController:UITableViewDelegate, UITableViewDataSource{
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
            
        
        if tableView == recentSearchTableView {
            return dummySearches.count
        }

        return places.count
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == recentSearchTableView {
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

        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PlaceTableViewCell.identifier, for: indexPath) as? PlaceTableViewCell else {
            return UITableViewCell()
        }

        
        cell.setPlace(place: places[indexPath.row])
        
        if indexPath.row == places.count - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.width, bottom: 0, right: 0)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == recentSearchTableView {
            return 80;
        }
        
        return 80;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if tableView == searchTableView {
            
            placeCellSelected$.accept(places[indexPath.row].id)
            
            return
        }
        
        
        
    }
    
}

extension HomeBottomSheetViewController:UISheetPresentationControllerDelegate{
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
          let isLarge = sheetPresentationController.selectedDetentIdentifier == .large
        homeScrollView.isScrollEnabled = isLarge
      }
}


extension HomeBottomSheetViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}




extension HomeBottomSheetViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        guard scrollView == searchTableView else { return }
        
        
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        let isAtBottom = (offsetY + 140) >= contentHeight - height
        
        if isAtBottom {
            bottomReached$.accept(Void())
        }
    }
    
   
    
}
