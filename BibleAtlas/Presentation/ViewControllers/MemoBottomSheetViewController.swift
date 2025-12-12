//
//  MemoBottomSheetViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/10/25.
//

import UIKit
import RxSwift
import RxRelay


class MemoBottomSheetViewController: UIViewController {
    
    private var memoBottomSheetViewModel:MemoBottomSheetViewModelProtocol?
    
    private let disposeBag = DisposeBag();
    
    private let viewLoaded$ = PublishRelay<Void>();
    
    private lazy var headerStackView = {
        let sv = UIStackView(arrangedSubviews: [cancelButton, headerLabel, confirmButton, confirmLoadingView]);
        sv.axis = .horizontal;
        sv.distribution = .equalSpacing;
        sv.alignment = .center;
        return sv;
    }()
    
    private let cancelButton = {
        let button = UIButton(type: .system);
        button.setTitle(L10n.Common.cancel, for: .normal)
        button.setTitleColor(.primaryBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        return button;
    }()
    
    private let headerLabel = {
        let label = HeaderLabel(text: L10n.Memo.addTitle);
        label.font = .boldSystemFont(ofSize: 18);
        return label;
    }()
    
    private lazy var confirmButton = {
        let button = UIButton(type: .system);
        button.setTitle(L10n.Common.done, for: .normal)
        button.setTitleColor(.primaryBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)

        return button;
    }()
    
    private let confirmLoadingView = LoadingView(style: .medium);
    
    
    private let descriptionTextView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = .mainItemBkg
        tv.textColor = .mainText
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.isScrollEnabled = true
        tv.isEditable = true
        tv.layer.cornerRadius = 8;
        tv.layer.masksToBounds = true;
        tv.text = ""
        tv.textContainerInset = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10) // ✅ 내부 여백 추가
        tv.autocorrectionType = .no
        tv.spellCheckingType = .no
     
        return tv
    }()
    
    
    private lazy var deleteMemoButton = {
        let button = IconTextButton(iconSystemName: "trash.fill", color: .primaryRed, labelText: L10n.Memo.delete);
        button.isEnabled = true
        return button;
    }()
    
    private let loadingView = LoadingView();

    private let errorRetryView = ErrorRetryView();
    
    
    private func setupUI(){
        view.addSubview(headerStackView);
        view.addSubview(descriptionTextView)
        view.addSubview(deleteMemoButton)
        view.addSubview(loadingView)
        view.addSubview(errorRetryView)
        
    }
    
    private func setupConstraints(){
        headerStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
        }
        
        descriptionTextView.snp.makeConstraints { make in
            make.top.equalTo(headerStackView.snp.bottom).offset(20);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
            make.height.equalTo(300)
        }
        
        deleteMemoButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(20);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
        }
        
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        errorRetryView.snp.makeConstraints { make in
            make.center.equalToSuperview();
        }
        
    }
    
    private func setupStyle(){
        view.backgroundColor = .mainBkg;
    }
    
    private func bindViewModel(){
        let cancelButtonTapped$ = cancelButton.rx.tap.asObservable();
        
        let confirmButtonTapped$ = confirmButton.rx.tap.asObservable();
            
        let confirmTappedWithText$ = confirmButtonTapped$
            .withLatestFrom(descriptionTextView.rx.text.orEmpty)
        
 
        
        let deleteButtonTapped$ = deleteMemoButton.rx.tap.asObservable();
        
        let refetchButtonTapped$ = errorRetryView.refetchTapped$
        
        let output = memoBottomSheetViewModel?.transform(input: MemoBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), refetchButtonTapped$: refetchButtonTapped$.asObservable(), cancelButtonTapped$: cancelButtonTapped$.asObservable(), confirmButtonTapped$: confirmTappedWithText$.asObservable(), deleteButtonTapped$: deleteButtonTapped$.asObservable()))
        
        
        output?.isCreatingOrUpdating$.observe(on: MainScheduler.instance).bind{ [ weak self ] isCreatingOrUpdating in
            
            if(isCreatingOrUpdating){
                self?.confirmButton.isHidden = true;
                self?.confirmLoadingView.start()
                self?.deleteMemoButton.isEnabled = false;
                
                self?.confirmButton.setTitle(nil, for: .normal)

            }
            else{
                self?.confirmButton.isHidden = false;
                self?.confirmLoadingView.stop()
                self?.confirmButton.setTitle(L10n.Common.done, for: .normal)
                self?.deleteMemoButton.isEnabled = true;


            }
            
            
        }.disposed(by: disposeBag)
        
        output?.isDeleting$.observe(on: MainScheduler.instance).bind{
            [weak self] isDeleting in
            self?.deleteMemoButton.setLoading(isDeleting)
            self?.confirmButton.isEnabled = !isDeleting
            
            
        }.disposed(by: disposeBag)
        

        
        
        
        output?.interactionError$
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: {[weak self] error in
                guard let error = error else {return}
                self?.showAlert(message: error.description)
            })
            .disposed(by: disposeBag)
        
        
        Observable.combineLatest(output!.isLoading$, output!.loadError$ , output!.memo$)
            .observe(on: MainScheduler.instance)
            .bind{ [weak self]
                 isLoading, error, memo in
                guard let self = self else { return }
                
                if let error = error {
                    switch(error){
                        default:
                        self.errorRetryView.setMessage(error.description);
                        self.descriptionTextView.isHidden = true;
                        self.deleteMemoButton.isHidden = true;
                        self.loadingView.isHidden = true;
                        self.errorRetryView.isHidden = false;
                        self.confirmButton.isEnabled = false;
                    }
                    return
                }
                
                if isLoading{
                    self.loadingView.start();
                    self.descriptionTextView.isHidden = true;
                    self.deleteMemoButton.isHidden = true;             
                    self.errorRetryView.isHidden = true;
                    return;
                }
                
                self.loadingView.stop();
                
                self.descriptionTextView.isHidden = false;
                
                if(memo.isEmpty){
                    self.deleteMemoButton.isHidden = true
                    self.headerLabel.text = L10n.Memo.addTitle
                }
                else{
                    self.descriptionTextView.text = memo
                    self.headerLabel.text = L10n.Memo.updateTitle
                    self.deleteMemoButton.isHidden = false
                    
                }

                
            }
            .disposed(by: disposeBag)
        
    }
    
    private func showAlert(message: String?) {
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.view.window != nil else { return }
            
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: L10n.Common.ok, style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI();
        setupConstraints();
        setupStyle();
        setupDismissKeyboardOnTap()
        bindViewModel();
        viewLoaded$.accept(Void())
    }
    
    init(memoBottomSheetViewModel:MemoBottomSheetViewModelProtocol){
        self.memoBottomSheetViewModel = memoBottomSheetViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}



#if DEBUG
extension MemoBottomSheetViewController {
    var _test_cancelButton: UIButton { cancelButton }
    var _test_confirmButton: UIButton { confirmButton }
    var _test_confirmLoadingView: LoadingView { confirmLoadingView }
    var _test_descriptionTextView: UITextView { descriptionTextView }
    var _test_deleteMemoButton: IconTextButton { deleteMemoButton }
    var _test_loadingView: LoadingView { loadingView }
    var _test_errorRetryView: ErrorRetryView { errorRetryView }
    var _test_headerLabel: UILabel { headerLabel }
}
#endif
