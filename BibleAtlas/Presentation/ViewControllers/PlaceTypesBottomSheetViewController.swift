//
//  PlacesByTypeViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/11/25.
//

import UIKit
import RxSwift
import RxRelay

final class PlaceTypesBottomSheetViewController: UIViewController {
    
    
    private var placeTypes:[PlaceTypeWithPlaceCount] = [];
    
    private let disposeBag = DisposeBag()
    
    private var placeTypesBottomSheetViewModel: PlaceTypesBottomSheetViewModelProtocol?
    
    private let placeTypeCellTapped$ = PublishRelay<Int>()
    
    
    private let viewLoaded$ = PublishRelay<Void>();
    
    private let bottomReached$ = PublishRelay<Void>();
    
    
    private var isBottomEmitted = false

    private var isFetching: Bool = false;

    
    private lazy var headerStackView = {
        let sv = UIStackView(arrangedSubviews: [headerLabel, closeButton]);
        sv.axis = .horizontal;
        sv.distribution = .fillProportionally;
        sv.alignment = .center;
        return sv;
    }()
    
    
    private let headerLabel = HeaderLabel(text: "Places By Type");
    private let closeButton = CircleButton(iconSystemName: "xmark");

    
    private lazy var collectionView:UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.delegate = self
        cv.dataSource = self
        cv.register(PlaceTypeCell.self,forCellWithReuseIdentifier: PlaceTypeCell.identifier);
        cv.backgroundColor = .mainItemBkg
        cv.layer.cornerRadius = 8;
        cv.layer.masksToBounds = true
        cv.isScrollEnabled = true
        cv.register(FooterLoadingReusableView.self,
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                    withReuseIdentifier: FooterLoadingReusableView.identifier)
        
        
        return cv
    }()
    
    private let loadingView = LoadingView();

    private let footerLoadingView = LoadingView(style: .medium);

    private let emptyLabel = EmptyLabel();
    
    private let errorRetryView = ErrorRetryView();
    
    private func setupUI(){
        view.addSubview(headerStackView)
        view.addSubview(collectionView)
        view.addSubview(loadingView)
        view.addSubview(emptyLabel);
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
        
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(headerStackView.snp.bottom).offset(20);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);
            make.bottom.equalToSuperview().inset(20);
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
        
        let refetchButtonTapped$ = errorRetryView.refetchTapped$

        let output = placeTypesBottomSheetViewModel?.transform(input: PlaceTypesBottomSheetViewModel.Input(placeTypeCellTapped$: placeTypeCellTapped$.asObservable(), closeButtonTapped$:closeButtonTapped$.asObservable(), viewLoaded$: viewLoaded$.asObservable(), bottomReached$: bottomReached$.asObservable(), refetchButtonTapped$: refetchButtonTapped$.asObservable()))
        

        output?.placeTypes$.observe(on: MainScheduler.instance).bind{
            [weak self] placeTypes in
            self?.placeTypes = placeTypes;
            self?.collectionView.reloadData();
        }.disposed(by: disposeBag)
        
        Observable
            .combineLatest(output!.isInitialLoading$, output!.placeTypes$, output!.error$)
            .observe(on: MainScheduler.instance)
            .bind{ [weak self] isLoading, placeTypes, error in
                
                guard let self = self else { return }
                    
                if let error = error {
                    switch(error){
                    default:
                        self.errorRetryView.setMessage(error.description)
                        self.collectionView.isHidden = true;
                        self.emptyLabel.isHidden = true;
                        self.loadingView.isHidden = true;
                        self.errorRetryView.isHidden = false;
                        self.isBottomEmitted = false

                    }
                    return;
                }
                
                
                
                if isLoading {
                    self.loadingView.start();
                    self.collectionView.isHidden = true;
                    self.emptyLabel.isHidden = true;
                    self.errorRetryView.isHidden = true;
                    return;
                }
                
                self.loadingView.stop();
                
                let isEmpty = !isLoading && placeTypes.isEmpty;
                
                self.emptyLabel.isHidden = !isEmpty;
                self.collectionView.isHidden = isEmpty;
                
            }.disposed(by: disposeBag)
        
        
        output?.isFetchingNext$
            .observe(on: MainScheduler.instance)
            .bind { [weak self] isFetching in
                guard let self = self else { return }

                self.isFetching = isFetching;
                self.collectionView.reloadSections(IndexSet(integer: 0))

            }.disposed(by: disposeBag)
        
  
        
        
    }
    
    
    init(vm:PlaceTypesBottomSheetViewModelProtocol){
        self.placeTypesBottomSheetViewModel = vm
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
        viewLoaded$.accept(Void())
    }

}

extension PlaceTypesBottomSheetViewController: UICollectionViewDelegate, UICollectionViewDataSource{
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return placeTypes.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlaceTypeCell.identifier, for: indexPath) as! PlaceTypeCell
        
            let placeType = placeTypes[indexPath.row]
            cell.setPlace(placeType: placeType)
      
            
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let placeType = placeTypes[indexPath.row]
        placeTypeCellTapped$.accept(placeType.id)

    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionFooter else {
            return UICollectionReusableView()
        }

        let footer = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: FooterLoadingReusableView.identifier,
            for: indexPath
        ) as! FooterLoadingReusableView

        
        if isFetching {
            footer.start()
        } else {
            footer.stop()
        }

        return footer
    }
    
    
}

extension PlaceTypesBottomSheetViewController:UICollectionViewDelegateFlowLayout{
    
        func collectionView(_ collectionView: UICollectionView,
                           layout collectionViewLayout: UICollectionViewLayout,
                           sizeForItemAt indexPath: IndexPath) -> CGSize {

           let spacing: CGFloat = 10
           let totalSpacing = spacing * 2 + spacing * 2 // 좌우 inset + 두 번의 간격
           let itemWidth = (collectionView.bounds.width - totalSpacing) / 3

           return CGSize(width: itemWidth, height: itemWidth + 20) // height는 적절히 조절
       }

       func collectionView(_ collectionView: UICollectionView,
                           layout collectionViewLayout: UICollectionViewLayout,
                           minimumLineSpacingForSectionAt section: Int) -> CGFloat {
           return 0
       }

       func collectionView(_ collectionView: UICollectionView,
                           layout collectionViewLayout: UICollectionViewLayout,
                           minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
           return 10
       }
    
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 44)
    }
    
}


extension PlaceTypesBottomSheetViewController:UIScrollViewDelegate{
    
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
