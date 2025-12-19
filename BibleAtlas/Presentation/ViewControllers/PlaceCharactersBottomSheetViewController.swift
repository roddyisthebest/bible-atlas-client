//
//  PlacesByCharacterBottomSheetViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/11/25.
//

import UIKit
import RxSwift
import RxRelay

final class PlaceCharactersBottomSheetViewController: UIViewController {
    
    private var placeCharacters:[PlacePrefix] = [];

    private var placeCharactersBottomSheetViewModel:PlaceCharactersBottomSheetViewModelProtocol?
    
    private let placeCharacterCellTapped$ = PublishRelay<String>()
    
    private let viewLoaded$ = PublishRelay<Void>();
    
    private var isFetching: Bool = false;
    
    private let disposeBag = DisposeBag();
    
    private let dummyCharacters:[String] = (65...90).map { String(UnicodeScalar($0)!) }
    
    private var myDetents:[UISheetPresentationController.Detent] = []
    
    private lazy var headerStackView = {
        let sv = UIStackView(arrangedSubviews: [headerLabel, closeButton]);
        sv.axis = .horizontal;
        sv.distribution = .fillProportionally;
        sv.alignment = .center;
        return sv;
    }()
    
    
    private let headerLabel = HeaderLabel(text: L10n.PlaceCharacters.title);
    private let closeButton = CircleButton(iconSystemName: "xmark");

    
    private lazy var collectionView:UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.delegate = self
        cv.dataSource = self
        cv.register(PlaceCharacterCell.self,forCellWithReuseIdentifier: PlaceCharacterCell.identifier);
        cv.backgroundColor = .mainItemBkg
        cv.layer.cornerRadius = 8;
        cv.layer.masksToBounds = true
        cv.isScrollEnabled = true
        return cv
    }()
    
    private let loadingView = LoadingView();
    
    private let emptyLabel = EmptyLabel(text:L10n.PlaceCharacters.empty);
    
    private let errorRetryView = ErrorRetryView();
    
    
    
    private func setupUI(){
        view.addSubview(headerStackView)
        view.addSubview(collectionView)
        view.addSubview(loadingView)
        view.addSubview(emptyLabel);
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
        
        let refetchButtonTapped$ = errorRetryView.refetchTapped$;
        
        
        
        let output = placeCharactersBottomSheetViewModel?.transform(input:PlaceCharactersBottomSheetViewModel.Input(placeCharacterCellTapped$: placeCharacterCellTapped$.asObservable(), closeButtonTapped$: closeButtonTapped$, viewLoaded$: viewLoaded$.asObservable(), refetchButtonTapped$: refetchButtonTapped$.asObservable()))
        
        
        
        output?.placeCharacter$.observe(on: MainScheduler.instance).bind{[weak self] placeCharacters in
            self?.placeCharacters = placeCharacters;
            self?.collectionView.reloadData();
        }.disposed(by: disposeBag)
        
        Observable.combineLatest(output!.isInitialLoading$, output!.placeCharacter$, output!.error$)
            .observe(on: MainScheduler.instance)
            .bind{[weak self] isLoading, placeCharacters, error in
                guard let self = self else { return }
                
                if let error = error {
                    switch(error){
                    default:
                        self.errorRetryView.setMessage(error.description)
                        self.collectionView.isHidden = true;
                        self.emptyLabel.isHidden = true;
                        self.loadingView.isHidden = true;
                        self.errorRetryView.isHidden = false;

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
                self.errorRetryView.isHidden = true
                
                
                let isEmpty = !isLoading && placeCharacters.isEmpty;
                
                self.emptyLabel.isHidden = !isEmpty;
                self.collectionView.isHidden = isEmpty;

                    
            }.disposed(by: disposeBag)
        
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
    
    
    init(vm:PlaceCharactersBottomSheetViewModelProtocol){
        self.placeCharactersBottomSheetViewModel = vm
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI();
        setupStyle()
        setupConstraints()
        bindViewModel()
        viewLoaded$.accept(Void())
    }
    

}


extension PlaceCharactersBottomSheetViewController: UICollectionViewDelegate, UICollectionViewDataSource{
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return placeCharacters.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlaceCharacterCell.identifier, for: indexPath) as! PlaceCharacterCell
        
            let placeCharacter = placeCharacters[indexPath.item];
            cell.setPlaceCharacter(placeCharacter: placeCharacter)

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let character = placeCharacters[indexPath.item]
        placeCharacterCellTapped$.accept(character.prefix.uppercased())
    }
    
    
}

extension PlaceCharactersBottomSheetViewController:UICollectionViewDelegateFlowLayout{
    
        func collectionView(_ collectionView: UICollectionView,
                           layout collectionViewLayout: UICollectionViewLayout,
                           sizeForItemAt indexPath: IndexPath) -> CGSize {

           let spacing: CGFloat = 10
           let totalSpacing = spacing * 2 + spacing * 2 // 좌우 inset + 두 번의 간격
           let itemWidth = (collectionView.bounds.width - totalSpacing) / 3

           return CGSize(width: itemWidth, height: itemWidth ) // height는 적절히 조절
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
    
    
}


#if DEBUG
extension PlaceCharactersBottomSheetViewController {
    var _test_headerLabel: UILabel { headerLabel }
    var _test_collectionView: UICollectionView { collectionView }
    var _test_loadingView: LoadingView { loadingView }
    var _test_emptyLabel: EmptyLabel { emptyLabel }
    var _test_errorRetryView: ErrorRetryView { errorRetryView }
    var _test_closeButton: CircleButton { closeButton }
}
#endif

