//
//  SearchResultViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 6/21/25.
//

import UIKit
import RxSwift
import RxCocoa

class SearchResultViewController: UIViewController {

    private var searchResultViewModel:SearchResultViewModelProtocol?
    
    private let bottomReached$ = PublishRelay<Void>();
    
    private let placeCellSelected$ = PublishRelay<String>();
    
    private let disposeBag = DisposeBag()
    
    private var places: [Place] = [];
    

    private lazy var bodyView = {
        let v = UIView();
        
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
        footerLoadingView.frame = CGRect(x: 0, y: 0, width: tv.bounds.width, height: 44)
        
        return tv;
    }()
    
    private let searchingView = LoadingView();
    
    private let footerLoadingView = LoadingView(style: .medium);
    
    init(searchResultViewModel: SearchResultViewModelProtocol) {
        self.searchResultViewModel = searchResultViewModel

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
        setupConstraints();
        bindViewModel();
        print("search result vc")
    }
    
    private func setupUI(){
        view.addSubview(bodyView)
        
    }
    
    
    private func setupConstraints(){
        bodyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        searchTableView.snp.makeConstraints { make in
            make.top.left.equalToSuperview().offset(20);
            make.bottom.right.equalToSuperview().inset(20)
        }
        
        searchingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    
    
    private func bindViewModel(){
        let output = searchResultViewModel?.transform(input: SearchResultViewModel.Input(
            bottomReached$: bottomReached$.asObservable(), placeCellSelected$: placeCellSelected$.asObservable()))
        
        output?.places$
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: {[weak self] places in
                self?.places = places
                self?.searchTableView.reloadData()
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
        
        output?.isSearching$
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isSearching in
                
                if(isSearching){
                    self?.searchTableView.isUserInteractionEnabled = false;
                    self?.searchingView.start()
                }
                else{
                    self?.searchTableView.isUserInteractionEnabled = true;
                    self?.searchingView.stop()
                }
            })
            .disposed(by: disposeBag)
    }

}


extension SearchResultViewController:UITableViewDelegate, UITableViewDataSource{
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
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
        return 80;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        placeCellSelected$.accept(places[indexPath.row].id)
        
    }
}

extension SearchResultViewController:UIScrollViewDelegate{
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        let isAtBottom = (offsetY + 140) >= contentHeight - height
        
        if isAtBottom {
            bottomReached$.accept(Void())
        }
    }
    
}
