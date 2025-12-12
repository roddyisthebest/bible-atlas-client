//
//  BiblesBottomSheetViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 9/22/25.
//

import UIKit
import RxSwift
import RxRelay

final class BiblesBottomSheetViewController: UIViewController {
    
    private var bibleBookCounts:[BibleBookCount] = [];

    private var biblesBottomSheetViewModel:BiblesBottomSheetViewModelProtocol?
    
    private let cellTapped$ = PublishRelay<BibleBook>()
    
    private let viewLoaded$ = PublishRelay<Void>();
    
    private var isFetching: Bool = false;
    
    private let disposeBag = DisposeBag();
    
    private var myDetents:[UISheetPresentationController.Detent] = []
    
    
    private lazy var headerStackView = {
        let sv = UIStackView(arrangedSubviews: [headerLabel, closeButton]);
        sv.axis = .horizontal;
        sv.distribution = .fillProportionally;
        sv.alignment = .center;
        return sv;
    }()
    
    
    private let headerLabel = HeaderLabel(text: L10n.Bibles.title);
    private let closeButton = CircleButton(iconSystemName: "xmark");

    
    private lazy var collectionView:UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.delegate = self
        cv.dataSource = self
        cv.register(BibleBookCell.self,forCellWithReuseIdentifier: BibleBookCell.identifier);
        cv.backgroundColor = .mainItemBkg
        cv.layer.cornerRadius = 8;
        cv.layer.masksToBounds = true
        cv.isScrollEnabled = true
        return cv
    }()
    
    private let loadingView = LoadingView();
    
    private let emptyLabel = EmptyLabel();
    
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
        
        
        
        let output = biblesBottomSheetViewModel?.transform(input: BiblesBottomSheetViewModel.Input(cellTapped$: cellTapped$.asObservable(), closeButtonTapped$: closeButtonTapped$.asObservable(), viewLoaded$: viewLoaded$.asObservable(), refetchButtonTapped$: refetchButtonTapped$.asObservable()))
        
        
        
        output?.bibleBookCounts$.observe(on: MainScheduler.instance).bind{[weak self] bibleBookCounts in
            self?.bibleBookCounts = bibleBookCounts;
            self?.collectionView.reloadData();
        }.disposed(by: disposeBag)
        
        Observable.combineLatest(output!.isInitialLoading$, output!.bibleBookCounts$, output!.error$)
            .observe(on: MainScheduler.instance)
            .bind{[weak self] isLoading, bibleBookCounts, error in
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
                
                
                let isEmpty = !isLoading && bibleBookCounts.isEmpty;
                
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
    
    
    init(vm:BiblesBottomSheetViewModelProtocol){
        super.init(nibName: nil, bundle: nil)
        self.biblesBottomSheetViewModel = vm
        self.bindViewModel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI();
        setupStyle()
        setupConstraints()

        viewLoaded$.accept(Void())
    }
    

}


extension BiblesBottomSheetViewController: UICollectionViewDelegate, UICollectionViewDataSource{
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bibleBookCounts.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BibleBookCell.identifier, for: indexPath) as! BibleBookCell
        
            let bibleBookCount = bibleBookCounts[indexPath.item];
            
            cell.setBibleBook(bibleBookCount: bibleBookCount)

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let bibleBookCount = bibleBookCounts[indexPath.item];
        cellTapped$.accept(bibleBookCount.bible)
    }
    
    
}

extension BiblesBottomSheetViewController:UICollectionViewDelegateFlowLayout{
    
        func collectionView(_ collectionView: UICollectionView,
                           layout collectionViewLayout: UICollectionViewLayout,
                           sizeForItemAt indexPath: IndexPath) -> CGSize {

           let spacing: CGFloat = 10
           let totalSpacing = spacing * 2 + spacing * 2 // 좌우 inset + 두 번의 간격
           let itemWidth = (collectionView.bounds.width - totalSpacing) / 3

           return CGSize(width: itemWidth, height: itemWidth + 20 ) // height는 적절히 조절
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
extension BiblesBottomSheetViewController {
    var _test_headerLabel: UILabel { headerLabel }
    var _test_collectionView: UICollectionView { collectionView }
    var _test_loadingView: LoadingView { loadingView }
    var _test_emptyLabel: UILabel { emptyLabel }
    var _test_errorRetryView: ErrorRetryView { errorRetryView }
    var _test_closeButton: CircleButton { closeButton }
}
#endif
