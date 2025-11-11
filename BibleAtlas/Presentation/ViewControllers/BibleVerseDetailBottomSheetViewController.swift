//
//  BibleVerseDetailBottomSheetViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 6/4/25.
//

import UIKit
import RxSwift
import RxRelay

class BibleVerseDetailBottomSheetViewController: UIViewController {

    private var bibleVerseDetailBottomSheetViewModel:BibleVerseDetailBottomSheetViewModelProtocol?
    private let disposeBag = DisposeBag();

    private let viewLoaded$ = PublishRelay<Void>();

    
    
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
    
    
    private let textView = {
        let tv = UITextView();
        tv.backgroundColor = .mainItemBkg;
        tv.isEditable = false;
        tv.layer.cornerRadius = 8;
        tv.layer.masksToBounds = true;
        tv.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        tv.font = .systemFont(ofSize: 16) 
        return tv;
    }()
    
    private let loadingView = LoadingView();
    
    private let errorRetryView = ErrorRetryView();
    
    
    init(bibleVerseDetailBottomSheetViewModel:BibleVerseDetailBottomSheetViewModelProtocol) {
        self.bibleVerseDetailBottomSheetViewModel = bibleVerseDetailBottomSheetViewModel;
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupStyle()
        setupConstraints()
        bindViewModel();
        viewLoaded$.accept(Void())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupStyle(){
        view.backgroundColor = .mainBkg;
    }
    
    private func setupUI(){
        view.addSubview(headerStackView)
        view.addSubview(textView)
        view.addSubview(loadingView)
        view.addSubview(errorRetryView)
    }
    
    private func setupConstraints(){
        headerStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);
        }
        
        textView.snp.makeConstraints { make in
            make.top.equalTo(headerStackView.snp.bottom).offset(20);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);
            make.bottom.equalToSuperview().offset(-20);
        }
        
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        errorRetryView.snp.makeConstraints { make in
            make.center.equalToSuperview();
        }
    }
    
    private func bindViewModel(){
        let closeButtonTapped$ = closeButton.rx.tap.asObservable();
        let refetchTapped$ = errorRetryView.refetchTapped$;
        
        let output = bibleVerseDetailBottomSheetViewModel?.transform(input: BibleVerseDetailBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), refetchButtonTapped$: refetchTapped$.asObservable(), closeButtonTapped$: closeButtonTapped$))
        
        
        Observable.combineLatest(output!.bibleVerse$, output!.placeName$)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (bibleVerse, placeName) in
                guard let self = self else { return }

                if let kw = placeName?.trimmingCharacters(in: .whitespacesAndNewlines), !kw.isEmpty {
                    self.textView.attributedText = makeHighlightedVerse(
                        bibleVerse,
                        keyword: kw,
                        mode: .substring // ✅ 부분 매치
                    )

                    // 선택: 첫 매치 위치로 스크롤
                    if let s = self.textView.attributedText?.string as NSString? {
                        let r = s.range(of: kw, options: .caseInsensitive)
                        if r.location != NSNotFound { self.textView.scrollRangeToVisible(r) }
                    }
                } else {
                    self.textView.attributedText = NSAttributedString(
                        string: bibleVerse,
                        attributes: [.font: UIFont.systemFont(ofSize: 16), .foregroundColor: UIColor.mainText]
                    )
                }
            })
            .disposed(by: disposeBag)

  
        
        output?.title$.observe(on: MainScheduler.instance).bind{
            [weak self] title in
            self?.headerLabel.text = title
        }.disposed(by: disposeBag)
        Observable.combineLatest(output!.isLoading$, output!.error$)
            .observe(on: MainScheduler.instance)
            .bind{ [weak self] isLoading, error in
                guard let self = self else { return }
                
                if let error = error {
                    switch(error){
                        default:
                        self.errorRetryView.setMessage(error.description);
                        self.textView.isHidden = true;
                        self.loadingView.isHidden = true;
                        self.errorRetryView.isHidden = false;
                    }
                    return
                }
                if isLoading{
                    self.loadingView.start();
                    self.textView.isHidden = true;
                    self.errorRetryView.isHidden = true;
                    return;
                }
                
                
                self.loadingView.stop();
                self.textView.isHidden = false;
                
            }
            .disposed(by: disposeBag)
        
    }
    

}
