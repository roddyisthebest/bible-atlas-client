//
//  RecentSearchesBottomSheetViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 7/9/25.
//

import UIKit
import RxSwift
import RxRelay

class RecentSearchesBottomSheetViewController: UIViewController {
    
    private var recentSearchesBottomSheetViewModel:RecentSearchesBottomSheetViewModelProtocol?
    
    private let disposeBag = DisposeBag();
    
    private let bottomReached$ = PublishRelay<Void>();
    private let viewLoaded$ = PublishRelay<Void>();

    private let cellSelected$ = PublishRelay<String>();
    
    private var recentSearches:[RecentSearchItem] = [];
    
    
    
    private lazy var headerStackView = {
        let sv = UIStackView(arrangedSubviews: [headerLabel, buttonStackView]);
        sv.axis = .horizontal;
        sv.distribution = .fill;
        sv.alignment = .center
        
        return sv;
    }()
    
    private lazy var buttonStackView = {
        let sv = UIStackView(arrangedSubviews: [allClearButton, closeButton]);
        sv.axis = .horizontal;
        sv.distribution = .fill;
        sv.alignment = .center
        sv.spacing = 10;
        return sv;
    }()
    
    
    private let headerLabel = HeaderLabel(text: L10n.RecentSearches.title);
    
    private let allClearButton = {
        let button = UIButton();
        button.setTitle(L10n.RecentSearches.clearAll, for: .normal)
        button.setTitleColor(.primaryBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15);
        return button;
    }()
    private let closeButton = CircleButton(iconSystemName: "xmark")
    
    private lazy var tableView = {
        let tv = UITableView();
        tv.register(RecentSearchTableViewCell.self, forCellReuseIdentifier: RecentSearchTableViewCell.identifier)
        
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
    
    private let loadingView = LoadingView();
    
    private let footerLoadingView = LoadingView(style: .medium);
    
    private let emptyLabel = EmptyLabel(text: L10n.RecentSearches.empty);
    
    private let errorRetryView = ErrorRetryView();

    private func setupUI(){
        view.addSubview(headerStackView);
        view.addSubview(tableView);
        view.addSubview(loadingView)
        view.addSubview(emptyLabel)
        view.addSubview(errorRetryView)

    }
    
    
    private func setupStyle(){
        view.backgroundColor = .mainBkg;
    }
    
    private func setupConstraints(){
        headerStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);
            make.height.equalTo(44)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerStackView.snp.bottom).offset(20);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);
            make.bottom.equalToSuperview().offset(-20);
            
        }
        
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        emptyLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        errorRetryView.snp.makeConstraints { make in
            make.center.equalToSuperview();
        }
        
       
    }
    

    
    
    private func bindViewModel(){
        let closeButtonTapped$ = closeButton.rx.tap.asObservable();

        let retryButtonTapped$ = errorRetryView.refetchTapped$.asObservable();
        let allClearButtonTapped$ = allClearButton.rx.tap.asObservable();
        
        let output = recentSearchesBottomSheetViewModel?.transform(input: RecentSearchesBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), closeButtonTapped$: closeButtonTapped$, cellSelected$: cellSelected$.asObservable(), bottomReached$: bottomReached$.asObservable(), retryButtonTapped$: retryButtonTapped$, allClearButtonTapped$: allClearButtonTapped$))
        
        output?.errorToInteract$
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .bind{ [weak self] error in
                
                self?.showErrorAlert(message: error?.description ?? "unknown error")
            }
            .disposed(by: disposeBag)
        
        
        Observable.combineLatest(output!.isInitialLoading$, output!.errorToFetch$, output!.recentSearches$)
            .observe(on: MainScheduler.instance)
            .bind{
                [weak self] isLoading, error, recentSearches in
                guard let self = self else {return}
                
                if let error = error {
                    switch error {
                
                    default:
                        self.errorRetryView.setMessage(error.description ?? "unknown error")
                        self.tableView.isHidden = true
                        self.emptyLabel.isHidden = true
                        self.loadingView.isHidden = true
                        self.errorRetryView.isHidden = false
                    }
                    return;
                }
                
                if isLoading {
                    self.loadingView.start();
                    self.tableView.isHidden = true
                    self.emptyLabel.isHidden = true
                    self.errorRetryView.isHidden = true
                    return;
                }
                
                
                
                self.loadingView.stop()

                let isEmpty = !isLoading && recentSearches.isEmpty
                self.emptyLabel.isHidden = !isEmpty
                self.tableView.isHidden = isEmpty
                    
                if(!isEmpty){
                    self.recentSearches = recentSearches
                    self.tableView.reloadData()
                    self.allClearButton.isHidden = false
                }else{
                    self.allClearButton.isHidden = true
                }
                
                
                
            }.disposed(by: disposeBag)
        
        
    }
    
    init(recentSearchesBottomSheetViewModel:RecentSearchesBottomSheetViewModelProtocol) {
        self.recentSearchesBottomSheetViewModel = recentSearchesBottomSheetViewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupStyle()
        setupConstraints()
        bindViewModel()
        
        self.viewLoaded$.accept(())
       
    }
    

}


extension RecentSearchesBottomSheetViewController:UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RecentSearchTableViewCell.identifier, for: indexPath) as? RecentSearchTableViewCell else {
            return UITableViewCell()
        }

        cell.setText(text: recentSearches[indexPath.row].name, koreanText: recentSearches[indexPath.row].koreanName)
        if indexPath.row == recentSearches.count - 1 {
               cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.width, bottom: 0, right: 0)
           } else {
               cell.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        }
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        cellSelected$.accept(recentSearches[indexPath.row].id)
        
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recentSearches.count;
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80;
    }
}


extension RecentSearchesBottomSheetViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        let isAtBottom = offsetY >= contentHeight - height
        
        if isAtBottom {
            bottomReached$.accept(())

        }
    }
    
   
    
}
