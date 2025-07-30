//
//  PlacesByTypeBottomSheetViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/15/25.
//

import UIKit
import RxSwift
import RxRelay

import UIKit
import RxSwift
import RxRelay

final class PlacesByTypeBottomSheetViewController: UIViewController {

    private var isBottomEmitted = false

    private var placesByTypeBottomSheetViewModel:PlacesByTypeBottomSheetViewModelProtocol?
    
    private let bottomReached$ = PublishRelay<Void>();
    
    private let viewLoaded$ = PublishRelay<Void>();
    
    private let placeCellTapped$ = PublishRelay<(String)>()

    private let disposeBag = DisposeBag();

    private var places:[Place] = [];
    
    private lazy var headerStackView = {
        let v = UIView();
        
        v.snp.makeConstraints { make in
            make.width.height.equalTo(30);
        }
        
        let sv = UIStackView(arrangedSubviews: [v, headerLabel, closeButton]);
        sv.axis = .horizontal;
        sv.distribution = .equalSpacing;
        sv.alignment = .center;
        
        return sv;
    }()
    
    
    private let headerLabel = {
        
        let label = HeaderLabel(text:"Land")
        label.font = .boldSystemFont(ofSize: 20)
        return label;
    }()
    
    private let closeButton = CircleButton(iconSystemName: "xmark");

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
    
    private let emptyLabel = EmptyLabel();
    
    private let errorRetryView = ErrorRetryView();

    private func setupUI(){
        view.addSubview(headerStackView);
        view.addSubview(tableView)
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
        let closeButtonTapped$ = closeButton.rx.tap.asObservable()

        let refetchButtonTapped$ = errorRetryView.refetchTapped$.asObservable();
        
        let output = placesByTypeBottomSheetViewModel?.transform(input: PlacesByTypeBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), placeCellTapped$: placeCellTapped$.asObservable(), closeButtonTapped$: closeButtonTapped$.asObservable(), bottomReached$: bottomReached$.asObservable(), refetchButtonTapped$: refetchButtonTapped$.asObservable()))
        
        
        output?.typeName$.observe(on:MainScheduler.instance).bind{
            [weak self] typeName in
            guard let typeName = typeName else {return }
            self?.headerLabel.text = "\(typeName)"
        }.disposed(by: disposeBag)

            
        output?.places$.observe(on: MainScheduler.instance).bind{
            [weak self] places in
            self?.places = places;
            self?.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        
        Observable
            .combineLatest(output!.isInitialLoading$, output!.places$, output!.error$)
            .observe(on: MainScheduler.instance)
            .bind { [weak self] isLoading, places, error in
                guard let self = self else { return }
                
               
                if let error = error {
                    switch error {
                
                    default:
                        self.errorRetryView.setMessage(error.description)
                        self.tableView.isHidden = true
                        self.emptyLabel.isHidden = true
                        self.loadingView.isHidden = true
                        self.errorRetryView.isHidden = false
                        self.isBottomEmitted = false
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
            }
            .disposed(by: disposeBag)
        
        output?.isFetchingNext$.observe(on: MainScheduler.instance)
            .bind { [weak self] isFetching in
                guard let self = self else { return }

                if isFetching {
                    self.footerLoadingView.start()
            
                } else {
                    self.footerLoadingView.stop()
                }
            }
            .disposed(by: disposeBag)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupStyle()
        setupConstraints()
        bindViewModel();
        viewLoaded$.accept(Void())
        
    }
    
    init(vm:PlacesByTypeBottomSheetViewModelProtocol){
        self.placesByTypeBottomSheetViewModel = vm
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        print("🔥 PlacesByCharacterVC deinit")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}



extension PlacesByTypeBottomSheetViewController:UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PlaceTableViewCell.identifier, for: indexPath) as? PlaceTableViewCell else {
            return UITableViewCell()
        }

        let place = places[indexPath.row];

        
        cell.setPlace(place: place);

        if indexPath.row == places.count - 1 {
               cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.width, bottom: 0, right: 0)
           } else {
               cell.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        }
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let place = places[indexPath.row];
        placeCellTapped$.accept(place.id);
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.count;
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80;
    }
}


extension PlacesByTypeBottomSheetViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        let isAtBottom = offsetY >= contentHeight - height
        
        if isAtBottom {
            if !isBottomEmitted {
                bottomReached$.accept(())
                isBottomEmitted = true
            }
        } else {
            isBottomEmitted = false
        }
    }
    
   
    
}
