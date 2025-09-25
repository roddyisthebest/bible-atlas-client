//
//  PopularPlacesBottomSheetViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 7/11/25.
//

import UIKit
import RxSwift
import RxRelay

class PopularPlacesBottomSheetViewController: UIViewController {

    private let disposeBag = DisposeBag();
    
    private let popularPlacesBottomSheetViewModel:PopularPlacesBottomSheetViewModelProtocol?
    
    private let bottomReached$ = PublishRelay<Void>();
    private let viewLoaded$ = PublishRelay<Void>();
    private let cellSelected$ = PublishRelay<String>();
    
    
    private var places:[Place] = []
    
    
    private lazy var headerStackView = {
        let sv = UIStackView(arrangedSubviews: [headerLabel, buttonStackView]);
        sv.axis = .horizontal;
        sv.distribution = .fill;
        sv.alignment = .center
        
        return sv;
    }()
    
    private lazy var buttonStackView = {
        let sv = UIStackView(arrangedSubviews: [closeButton]);
        sv.axis = .horizontal;
        sv.distribution = .fill;
        sv.alignment = .center
        sv.spacing = 10;
        return sv;
    }()
    
    
    private let headerLabel = HeaderLabel(text: L10n.PopularPlaces.title);
    
    private let closeButton = CircleButton(iconSystemName: "xmark")
    
    private lazy var tableView = {
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
    
    private let loadingView = LoadingView();
    
    private let footerLoadingView = LoadingView(style: .medium);
    
    private let emptyLabel = EmptyLabel(text: L10n.PopularPlaces.empty);
    
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

        let refetchButtonTapped$ = errorRetryView.refetchTapped$.asObservable();

        

        let output = popularPlacesBottomSheetViewModel?.transform(input: PopularPlacesBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), closeButtonTapped$: closeButtonTapped$.asObservable(), cellSelected$: cellSelected$.asObservable(), bottomReached$: bottomReached$.asObservable(), refetchButtonTapped$: refetchButtonTapped$.asObservable()
                                                                                                    ))
        

        
        
        
        Observable.combineLatest(output!.isInitialLoading$, output!.error$, output!.places$)
            .observe(on: MainScheduler.instance)
            .bind{
                [weak self] isLoading, error, places in
                guard let self = self else {return}
                
                if let error = error {
                    switch error {
                
                    default:
                        self.errorRetryView.setMessage(error.description)
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

                let isEmpty = !isLoading && places.isEmpty
                self.emptyLabel.isHidden = !isEmpty
                self.tableView.isHidden = isEmpty
                    
                if(!isEmpty){
                    self.places = places
                    self.tableView.reloadData()
        
                }
                
                
                
            }.disposed(by: disposeBag)
        
        
    }
    
    
    init(popularPlacesBottomSheetViewModel:PopularPlacesBottomSheetViewModelProtocol?) {
        self.popularPlacesBottomSheetViewModel = popularPlacesBottomSheetViewModel
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



extension PopularPlacesBottomSheetViewController:UITableViewDelegate, UITableViewDataSource {
    
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        cellSelected$.accept(places[indexPath.row].id)
        
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.count;
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80;
    }
}


extension PopularPlacesBottomSheetViewController: UIScrollViewDelegate {
    
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
