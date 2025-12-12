//
//  MyCollectionBottomSheetViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/26/25.
//

import UIKit
import RxSwift
import RxRelay
final class MyCollectionBottomSheetViewController: UIViewController {
    
    private var isBottomEmitted = false

    private var myCollectionBottomSheetViewModel:MyCollectionBottomSheetViewModelProtocol?;
    
    private let disposeBag = DisposeBag();

    private let bottomReached$ = PublishRelay<Void>();
    private let myCollectionViewLoaded$ = PublishRelay<Void>();

    private let placeTabelCellSelected$ = PublishRelay<String>();
    
    private var places:[Place] = [];
    
    private var myDetents:[UISheetPresentationController.Detent] = []
    
    
    private lazy var headerStackView = {
        let sv = UIStackView(arrangedSubviews: [headerLabel, closeButton]);
        sv.axis = .horizontal;
        sv.distribution = .fill;
        sv.alignment = .center
        
        return sv;
    }()
    
    
    private let headerLabel = HeaderLabel(text: "Favorites");
    
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
    
    private let emptyLabel = EmptyLabel(text: L10n.MyCollection.empty);
    
    private let errorRetryView = ErrorRetryView();

    
    private func setupUI(){
        view.addSubview(headerStackView);
        view.addSubview(tableView);
        view.addSubview(loadingView)
        view.addSubview(emptyLabel)
        view.addSubview(errorRetryView)
        self.myDetents = self.sheetPresentationController?.detents ?? []
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
        
        let output = myCollectionBottomSheetViewModel?.transform(input: MyCollectionBottomSheetViewModel.Input(myCollectionViewLoaded$: myCollectionViewLoaded$.asObservable(), closeButtonTapped$: closeButtonTapped$, placeTabelCellSelected$: placeTabelCellSelected$.asObservable(), bottomReached$: bottomReached$.asObservable(), refetchButtonTapped$: refetchButtonTapped$.asObservable()))
        
        output?.places$.observe(on: MainScheduler.instance).bind{
            [weak self] places in
            self?.places = places;
            self?.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        output?.filter$.observe(on: MainScheduler.instance).bind{
            [weak self] filter in
                switch(filter){
                case .like:
                    self?.headerLabel.text = L10n.MyCollection.favorites
                case .memo:
                    self?.headerLabel.text = L10n.MyCollection.memos
                case .save:
                    self?.headerLabel.text = L10n.MyCollection.saves
                }
            
          
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
        
        
        output?.forceMedium$.subscribe(onNext:{
            @MainActor [weak self] in
            self?.sheetPresentationController?.animateChanges{
                
                self?.sheetPresentationController?.detents = [.medium()]
                self?.sheetPresentationController?.largestUndimmedDetentIdentifier = .medium
                self?.sheetPresentationController?.selectedDetentIdentifier = .medium
            }
           
            
        }).disposed(by: disposeBag)
        
        
        output?.restoreDetents$.subscribe(onNext:{
            @MainActor [weak self] in
            self?.sheetPresentationController?.animateChanges{
                self?.sheetPresentationController?.detents = self?.myDetents ?? []
            }
        }).disposed(by: disposeBag)
        
        
    }
    

    deinit {
        print("🔥 MyCollectionBottomSheetVC deinit")
    }
    
    init(myCollectionBottomSheetViewModel:MyCollectionBottomSheetViewModelProtocol) {
        self.myCollectionBottomSheetViewModel = myCollectionBottomSheetViewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI();
        setupConstraints();
        setupStyle();
        bindViewModel();
        
        myCollectionViewLoaded$.accept(Void())
    }
    
 

}

extension MyCollectionBottomSheetViewController:UITableViewDelegate, UITableViewDataSource {
    
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
        placeTabelCellSelected$.accept(places[indexPath.row].id)
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.count;
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80;
    }
}


extension MyCollectionBottomSheetViewController: UIScrollViewDelegate {
    
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


#if DEBUG
extension MyCollectionBottomSheetViewController {
    var _test_headerLabel: UILabel { headerLabel }
    var _test_tableView: UITableView { tableView }
    var _test_emptyLabel: UILabel { emptyLabel }
    var _test_errorRetryView: ErrorRetryView { errorRetryView }
    var _test_loadingView: LoadingView { loadingView }
    var _test_closeButton: CircleButton { closeButton }
}
#endif
