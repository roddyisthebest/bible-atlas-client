//
//  SearchReadyViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 6/21/25.
//

import UIKit
import RxSwift
import RxCocoa
import RxRelay

final class SearchReadyViewController: UIViewController {


    
    private let disposeBag = DisposeBag();


    private var popularPlaces: [Place] = []
    private var recentSearches: [RecentSearchItem] = []

    private let popularPlaceCellTapped$ = PublishRelay<String>();
    
    private let recentSearchCellTapped$ = PublishRelay<String>();
    
    private let viewLoaded$ = PublishRelay<Void>();
    
    private let searchReadyViewModel: SearchReadyViewModelProtocol
    
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
        v.addSubview(recentSearchStackView);
        v.addSubview(popularPlaceStackView)
        return v
    }()
    
    
    private lazy var recentSearchHeaderStackView = {
        let sv = UIStackView(arrangedSubviews: [recentSearchLabel, recentSearchMoreButton])
        sv.axis = .horizontal;
        sv.distribution = .equalSpacing;
        sv.alignment = .fill;
        
        return sv;
    }()
    
    private let recentSearchMoreButton = {
        let button = UIButton();
        button.setTitle("More", for: .normal)
        button.setTitleColor(.primaryBlue, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 14)
        return button;
    }()
    
    private lazy var recentSearchStackView = {
        let sv = UIStackView(arrangedSubviews: [recentSearchHeaderStackView, recentSearchLine, recentSearchTableView]);
        sv.axis = .vertical;
        sv.distribution = .fill;
        sv.alignment = .fill
        sv.spacing = 3;
        
        return sv;
    }();
    
    
    private let recentSearchLabel = MainLabel(text:"Recent")
    private let recentSearchLine = {
        let v = UIView();
        v.backgroundColor = .mainLabelLine
        
        return v;
    }()
    private lazy var recentSearchTableView = {
        let tv = UITableView();
        
        tv.register(SearchTableViewCell.self, forCellReuseIdentifier: SearchTableViewCell.identifier)
        
        tv.delegate = self;
        tv.dataSource = self;
        tv.isScrollEnabled = false
        tv.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        
        tv.rowHeight = 40
        tv.separatorStyle = .none

        return tv;
    }()
    
    
    private lazy var popularPlaceHeaderStackView = {
        let sv = UIStackView(arrangedSubviews: [popularPlaceLabel, popularPlaceMoreButton])
        sv.axis = .horizontal;
        sv.distribution = .equalSpacing;
        sv.alignment = .fill;
        
        return sv;
    }()
    
    private let popularPlaceMoreButton = {
        let button = UIButton();
        button.setTitle("More", for: .normal)
        button.setTitleColor(.primaryBlue, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 14)
        return button;
    }()
    
    private lazy var popularPlaceStackView = {
        let sv = UIStackView(arrangedSubviews: [popularPlaceHeaderStackView, popularPlaceLine, popularPlaceTableView, loadingView, errorRetryView, emptyView]);
        sv.axis = .vertical;
        sv.distribution = .fill;
        sv.alignment = .fill
        sv.spacing = 3;
        return sv;
    }();
    
    
    
    private let popularPlaceLabel = MainLabel(text:"Popular")
    private let popularPlaceLine = {
        let v = UIView();
        v.backgroundColor = .mainLabelLine
        
        return v;
    }()
    
    private lazy var popularPlaceTableView = {
        let tv = UITableView();
        
        tv.register(PopularPlaceTableViewCell.self, forCellReuseIdentifier: PopularPlaceTableViewCell.identifier)
        
        tv.delegate = self;
        tv.dataSource = self;
        tv.isScrollEnabled = false
        tv.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        
        tv.rowHeight = 40
        tv.separatorStyle = .none

        return tv;
    }()
    
    private let loadingView = LoadingView();
    
    private let errorRetryView = ErrorRetryView(closable: false);

    private lazy var emptyView = {
        let v = UIView();
        v.isHidden = true
        v.addSubview(emptyLabel)
        return v;
    }()
    
    private let emptyLabel = {
        let label = UILabel();
        label.text = "인기 장소가 없습니다."
        label.textColor = .mainLabelText
        label.font = .boldSystemFont(ofSize: 15)
        return label;
    }()
    
    
    init(searchReadyViewModel: SearchReadyViewModelProtocol) {
           self.searchReadyViewModel = searchReadyViewModel
           super.init(nibName: nil, bundle: nil)
       }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupStyle();
        setupConstraints();
        bindViewModel();
        viewLoaded$.accept(Void())
    }
    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        recentSearchTableView.snp.updateConstraints { make in
//            make.height.equalTo(recentSearchTableView.contentSize.height)
//        }
//        
//        popularPlaceTableView.snp.updateConstraints{ make in
//            make.height.equalTo(popularPlaceTableView.contentSize.height)
//        }
//    
//    }
    

    private func setupUI() {
        view.addSubview(bodyView)
        recentSearchTableView.reloadData()
//        popularPlaceTableView.reloadData()
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
        
            
        recentSearchStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(30);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);
        }
        
        recentSearchLine.snp.makeConstraints { make in
            make.height.equalTo(1.5)
        }
        
        popularPlaceStackView.snp.makeConstraints { make in
            make.top.equalTo(recentSearchStackView.snp.bottom).offset(30)
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);
            make.bottom.equalToSuperview().inset(30);
        }
        
        popularPlaceLine.snp.makeConstraints { make in
            make.height.equalTo(1.5)
        }
        
        
        loadingView.snp.makeConstraints { make in
            make.height.equalTo(100)
        }
        
        emptyView.snp.makeConstraints { make in
            make.height.equalTo(100)
        }
            
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    
        
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bindViewModel(){
        
        let output = searchReadyViewModel.transform(input: SearchReadyViewModel.Input(refetchButtonTapped$: errorRetryView.refetchTapped$.asObservable(), popularPlaceCellTapped$: popularPlaceCellTapped$.asObservable(), recentSearchCellTapped$: recentSearchCellTapped$.asObservable(), viewLoaded$: viewLoaded$.asObservable()))
        
        output.recentSearches$
            .observe(on: MainScheduler.instance)
            .subscribe(onNext:{[weak self] recentSearches in
                
                guard let self = self else {
                    return
                }
                
                if(recentSearches.isEmpty){
                    self.recentSearchStackView.isHidden = true
                
                    self.popularPlaceStackView.snp.remakeConstraints { make in
                        make.top.equalToSuperview().offset(30)
                        make.leading.equalToSuperview().offset(20)
                        make.trailing.equalToSuperview().offset(-20)
                        make.bottom.equalToSuperview().inset(30)
                    }
                    
                    return
                }
                
                self.recentSearchStackView.isHidden = false
                self.popularPlaceStackView.snp.remakeConstraints { make in
                    make.top.equalTo(self.recentSearchStackView.snp.bottom).offset(30)
                    make.leading.equalToSuperview().offset(20)
                    make.trailing.equalToSuperview().offset(-20)
                    make.bottom.equalToSuperview().inset(30)
                }
                self.recentSearches = recentSearches;
                self.recentSearchTableView.reloadData()
                
                DispatchQueue.main.async {
                    self.recentSearchTableView.snp.updateConstraints { make in
                        make.height.equalTo(self.recentSearchTableView.contentSize.height)
                    }
                }
        }).disposed(by: disposeBag)
        
        Observable.combineLatest(output.isFetching$, output.errorToFetchPlaces$, output.popularPlaces$)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: {
            [weak self] isFetching, error, popularPlaces in
            guard let error = error else {
                if(isFetching){
                    self?.popularPlaceTableView.isHidden = true
                    self?.loadingView.start()
                }
                else{
                    self?.loadingView.stop()
                    
                    if(popularPlaces.isEmpty){
                        
                        self?.popularPlaceTableView.isHidden = true
                        self?.emptyView.isHidden = false;
                        self?.popularPlaceMoreButton.isHidden = true
                        return;
                    }
                    
                    self?.popularPlaceMoreButton.isHidden = false
                    self?.popularPlaceTableView.isHidden = false
                    self?.emptyView.isHidden = true;
                    
                    self?.popularPlaces = popularPlaces;
                    self?.popularPlaceTableView.reloadData()

                    
                    DispatchQueue.main.async {
                        self?.popularPlaceTableView.snp.updateConstraints { make in
                            make.height.equalTo(self?.popularPlaceTableView.contentSize.height ?? 0)
                        }
                    }
 
                }
                
                self?.errorRetryView.isHidden = true;
                return;
            }
            
            self?.loadingView.stop()

            self?.errorRetryView.isHidden = false;
                print(error.description)
            self?.errorRetryView.setMessage(error.description)

            
            
        }).disposed(by: disposeBag)
        
  
        
        
        
        
        
    }
    
}


extension SearchReadyViewController:UITableViewDelegate{

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(tableView == recentSearchTableView){
            recentSearchCellTapped$.accept(self.recentSearches[indexPath.row].id)
            return ;
        }
        
        popularPlaceCellTapped$.accept(self.popularPlaces[indexPath.row].id)

//        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}


extension SearchReadyViewController:UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(tableView == recentSearchTableView){
            return recentSearches.count
        }
        
        return popularPlaces.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if(tableView == recentSearchTableView){
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchTableViewCell.identifier, for: indexPath) as? SearchTableViewCell else {
                return UITableViewCell()
            }
            
            cell.setCotent(recentSearchItem: recentSearches[indexPath.row])
            return cell
        }
        
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PopularPlaceTableViewCell.identifier, for: indexPath) as? PopularPlaceTableViewCell else {
            return UITableViewCell()
        }
        
        cell.setCotent(place: popularPlaces[indexPath.row])
        
        return cell
   
    }
}
