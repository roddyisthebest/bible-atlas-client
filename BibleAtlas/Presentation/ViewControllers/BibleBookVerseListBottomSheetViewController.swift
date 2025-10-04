//
//  BibleBookVerseListBottomSheetViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 10/3/25.
//

import UIKit
import RxSwift
import RxRelay

final class BibleBookVerseListBottomSheetViewController: UIViewController {

    private var bibles:[Bible] = [];
    private var verses:[Verse] = [];
    
    private var bibleBookVerseListBottomSheetViewModel:BibleBookVerseListBottomSheetViewModelProtocol?
    
    private let viewLoaded$ = PublishRelay<Void>();
    
    private let bibleBookChanged$ = PublishRelay<BibleBook>();
    
    private let verseCellTapped$ = PublishRelay<Verse>();

    private let closeButtonTapped$ = PublishRelay<Void>();
    
    private let refetchButtonTapped$ = PublishRelay<Void>();

    private let disposeBag = DisposeBag();
    
    private lazy var headerStackView = {
        let sv = UIStackView(arrangedSubviews: [headerLabel, closeButton]);
        sv.axis = .horizontal;
        sv.distribution = .fill;
        sv.alignment = .center
        return sv
    }()
    
    private let headerLabel = HeaderLabel(text: L10n.VerseListSheet.defaultTitle)
    
    private let closeButton = CircleButton(iconSystemName: "xmark")
    
    private let loadingView = LoadingView();
    
    private let emptyLabel = EmptyLabel(text: L10n.VerseListSheet.empty);
    private let errorRetryView = ErrorRetryView();

    private lazy var bodyView = {
        let v = UIView();
        v.addSubview(selectButton)
        v.addSubview(collectionView)
        return v
    }()
    
    
    private let selectButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = L10n.VerseListSheet.selectBookPrompt
        config.image = UIImage(systemName: "chevron.down") // 또는 "arrowtriangle.down.fill"
        config.imagePlacement = .leading        // 아이콘 왼쪽
        config.imagePadding = 8                 // 아이콘-텍스트 간격
        config.contentInsets = .init(top: 10, leading: 14, bottom: 10, trailing: 14)
        config.baseForegroundColor = .detailLabelText     // 아이콘+텍스트 색
        config.baseBackgroundColor = .searchBarBkg
        button.configuration = config

        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true

        // 아이콘 크기/굵기 조절(옵션)
        button.configuration?.preferredSymbolConfigurationForImage =
            UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)

        return button
    }()

    
    private lazy var collectionView: UICollectionView = {
        let layout = LeftAlignedCollectionViewFlowLayout()
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.delegate = self
        cv.dataSource = self
        cv.register(VersedItemCell.self, forCellWithReuseIdentifier: VersedItemCell.identifier)
        cv.backgroundColor = .clear
    
        return cv
    }()
    
    
    

    init(vm:BibleBookVerseListBottomSheetViewModelProtocol){
        super.init(nibName: nil, bundle: nil)
        self.bibleBookVerseListBottomSheetViewModel = vm;
        self.bindViewModel();
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(){
        view.addSubview(headerStackView)
        view.addSubview(bodyView)
        view.addSubview(loadingView)
        view.addSubview(emptyLabel)
        view.addSubview(errorRetryView)
    }

    private func setupStyle(){
        view.backgroundColor = .mainBkg
        
    }
    
    
    
    private func bindViewModel(){
        
        let closeTapped$ = closeButton.rx.tap.asObservable()
        let refetchButtonTapped$ = errorRetryView.refetchTapped$.asObservable()
        let output = bibleBookVerseListBottomSheetViewModel?.transform(input: BibleBookVerseListBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), refetchButtonTapped$: refetchButtonTapped$, closeButtonTapped$: closeTapped$, bibleBookChanged$: bibleBookChanged$.asObservable(), verseCellTapped$: verseCellTapped$.asObservable()))
        
        
        output?.bibles$.observe(on:MainScheduler.instance).bind{
            [weak self] bibles in
            self?.selectButton.showsMenuAsPrimaryAction = true
            self?.selectButton.menu = UIMenu(title: L10n.VerseListSheet.selectBookPrompt, children: bibles.map { bible in
                UIAction(title: bible.bookName.title()) { [weak self] _ in
                    self?.bibleBookChanged$.accept(bible.bookName)
                }
            })
            
        }.disposed(by: disposeBag)
        
        output?.selectedBibleBookAndVerses$.observe(on: MainScheduler.instance).subscribe(onNext:{
            [weak self] (bibleBook,verses) in
            self?.selectButton.setTitle(bibleBook?.title(), for: .normal)
            self?.selectButton.setTitleColor(.mainText, for: .normal)
            
            self?.verses = verses
            
            if(verses.count>0){
                self?.collectionView.reloadData()
                
                self?.emptyLabel.isHidden = true;
            }else{
                self?.emptyLabel.isHidden = false
            }

            
            
        }).disposed(by: disposeBag)
        
        
        output?.place$.observe(on: MainScheduler.instance).subscribe(onNext:{
            [weak self]  place in
            
            guard let place = place else {
                self?.headerLabel.text = L10n.VerseListSheet.defaultTitle
                return
            }
            self?.headerLabel.text = L10n.VerseListSheet.title(L10n.isEnglish ? place.name : place.koreanName)
        }).disposed(by: disposeBag)
        
        
        Observable.combineLatest(output!.error$, output!.isLoading$).observe(on: MainScheduler.instance).subscribe(onNext:{
            [weak self] error, isLoading in
            
            if(isLoading){
                self?.bodyView.isHidden = true;
                self?.errorRetryView.isHidden = false
                self?.loadingView.isHidden = false
                return
            }
            
            guard let error = error else{
                
                self?.bodyView.isHidden = false;
                self?.errorRetryView.isHidden = true;
                self?.loadingView.isHidden = true;

                return;
            }
            
            self?.bodyView.isHidden = true;
            self?.errorRetryView.isHidden = false;
            self?.errorRetryView.setMessage(error.description)

        }).disposed(by: disposeBag)
        
        
    
    }
    
    
    private func setupConstraints(){
        headerStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);
        }
        
        bodyView.snp.makeConstraints { make in
            make.top.equalTo(headerStackView.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);

            make.bottom.equalToSuperview()
        }
        
        selectButton.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
        }
        
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(selectButton.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(20)
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI();
        self.setupStyle();
        self.setupConstraints();
        self.viewLoaded$.accept(())
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


extension BibleBookVerseListBottomSheetViewController:UICollectionViewDelegate, UICollectionViewDataSource{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return verses.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VersedItemCell.identifier, for: indexPath) as! VersedItemCell
        
        cell.verseTappedHandler = { [weak self] verse in
            self?.verseCellTapped$.accept(verse)
        }
        
        cell.configure(verse: verses[indexPath.item])

        return cell
    }
}
