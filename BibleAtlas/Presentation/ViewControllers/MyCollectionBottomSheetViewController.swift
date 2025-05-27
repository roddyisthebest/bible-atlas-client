//
//  MyCollectionBottomSheetViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/26/25.
//

import UIKit
import RxSwift
import RxRelay
import PanModal
final class MyCollectionBottomSheetViewController: UIViewController {
    
    private var isBottomEmitted = false

    private var myCollectionBottomSheetViewModel:MyCollectionBottomSheetViewModelProtocol?;
    
    private let disposeBag = DisposeBag();

    private let bottomReached$ = PublishRelay<Void>();
    private let myCollectionViewLoaded$ = PublishRelay<Void>();

    private let placeTabelCellSelected$ = PublishRelay<String>();
    
    private var places:[Place] = [];
    
    
    
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
        
        tv.tableFooterView = footerSpinnerView
        footerSpinnerView.frame = CGRect(x: 0, y: 0, width: tv.bounds.width, height: 44)
        
        return tv;
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private lazy var footerSpinnerView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .gray
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "내 컬렉션이 없습니다."
        label.textColor = .mainLabelText
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var errorStackView = {
        let sv = UIStackView(arrangedSubviews: [errorLabel, refetchButton]);
        sv.axis = .vertical;
        sv.distribution = .equalSpacing;
        sv.alignment = .center;
        sv.spacing = 10;
        sv.isHidden = true
        return sv;
    }()
    
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.text = "에러가 발생했습니다."
        label.textColor = .mainLabelText
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        return label
    }()
    
    private let refetchButton: UIButton = {
        let button = UIButton(type: .system)
        
        // 아이콘: SF Symbols 기준
        let icon = UIImage(systemName: "arrow.clockwise")
        button.setImage(icon, for: .normal)
        
        // 텍스트 (원한다면)
        button.setTitle("  다시 불러오기", for: .normal) // 아이콘 옆 텍스트
        button.setTitleColor(.mainLabelText, for: .normal)

        // 아이콘 + 텍스트 간격
        button.titleLabel?.font = .boldSystemFont(ofSize: 14)
        button.tintColor = .mainLabelText // 아이콘 색상
        
        return button
    }()

    
    private func setupUI(){
        view.addSubview(headerStackView);
        view.addSubview(tableView);
        view.addSubview(activityIndicator)
        view.addSubview(emptyLabel)
        view.addSubview(errorStackView)

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
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        emptyLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        errorStackView.snp.makeConstraints { make in
            make.center.equalToSuperview();
        }
        
       
    }
    
    private func bindViewModel(){
        let closeButtonTapped$ = closeButton.rx.tap.asObservable();
        let refetchButtonTapped$ = refetchButton.rx.tap.asObservable();
        
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
                    self?.headerLabel.text = "Favorite"
                case .memo:
                    self?.headerLabel.text = "Memo"
                case .save:
                    self?.headerLabel.text = "Save"
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
                        self.errorLabel.text = error.description
                        self.tableView.isHidden = true
                        self.emptyLabel.isHidden = true
                        self.activityIndicator.isHidden = true
                        self.errorStackView.isHidden = false
                        self.isBottomEmitted = false
                    }
                    return;
                }
                
                
                if isLoading {
                    self.activityIndicator.isHidden = false

                    self.activityIndicator.startAnimating()
                    self.tableView.isHidden = true
                    self.emptyLabel.isHidden = true
                    self.errorStackView.isHidden = true
                    return;
                }
                
                self.activityIndicator.stopAnimating()

                let isEmpty = !isLoading && places.isEmpty
                self.emptyLabel.isHidden = !isEmpty
                self.tableView.isHidden = isEmpty
            }
            .disposed(by: disposeBag)
        

        
        
        output?.isFetchingNext$.observe(on: MainScheduler.instance)
            .bind { [weak self] isFetching in
                guard let self = self else { return }

                if isFetching {
                    self.footerSpinnerView.isHidden = false;
                    self.footerSpinnerView.startAnimating()
                } else {
                    self.footerSpinnerView.isHidden = true;
                    self.footerSpinnerView.stopAnimating()
                }
            }
            .disposed(by: disposeBag)
        
        
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
//        placeTabelCellSelected$.accept(dummyPlaces[indexPath.row])
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
