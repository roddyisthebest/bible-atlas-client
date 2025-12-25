//
//  PlaceUpdateBottomSheetViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/11/25.
//

import UIKit
import RxRelay
import RxSwift

final class PlaceModificationBottomSheetViewController: UIViewController {
    
    
    private let cancelButtonTapped$ = PublishRelay<Void>()
    
    private let disposeBag = DisposeBag();
    
    private var placeModificationBottomSheetViewModel:PlaceModificationBottomSheetViewModelProtocol?

    private let confirmLoadingView = LoadingView(style:.medium);

    
    
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
        let label = HeaderLabel(text: L10n.PlaceModification.title);
        label.font = .boldSystemFont(ofSize: 18);
        return label;
    }()
    
    private let confirmButton = {
        let button = UIButton(type: .system);
        button.setTitle(L10n.Common.done, for: .normal)
        button.setTitleColor(.primaryBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        return button;
    }()
    
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
        tv.accessibilityLabel = L10n.PlaceModification.placeholder
        tv.textContainerInset = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10) // ✅ 내부 여백 추가
        return tv
    }()
    
    

    
    
    private func setupUI(){
        view.addSubview(headerStackView);
        view.addSubview(descriptionTextView)
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
    }
    
    private func setupStyle(){
        view.backgroundColor = .mainBkg;
    }
    
    
    private func showDefaultAlert(message: String?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.view.window != nil else { return }
            
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: L10n.Common.done, style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true)
        }
        
    }
    
    
    private func showAlertToDisplaySuccssion() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.view.window != nil else { return }
            
            let alert = UIAlertController(title: nil, message:L10n.PlaceModification.success, preferredStyle: .alert)
            let okAction = UIAlertAction(title: L10n.Common.ok, style: .default, handler: handleSuccessionAlertComplete)
            alert.addAction(okAction)
            self.present(alert, animated: true)
        }
        
    }
    
    private func handleSuccessionAlertComplete(_:UIAlertAction){
        cancelButtonTapped$.accept(Void())
    }
    
    private func bindViewModel(){
        cancelButton.rx.tap
            .bind(to: cancelButtonTapped$)
            .disposed(by: disposeBag)
        
        let confirmButtonTapped$ = confirmButton.rx.tap.asObservable();
            
        let confirmTappedWithText$ = confirmButtonTapped$
            .withLatestFrom(descriptionTextView.rx.text.orEmpty)
 
        let output = placeModificationBottomSheetViewModel?.transform(input: PlaceModificationBottomSheetViewModel.Input(cancelButtonTapped$: cancelButtonTapped$.asObservable(), confirmButtonTapped$: confirmTappedWithText$))
        
        
        output?.interactionError$
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: {[weak self] error in
                guard let error = error else {return}
                self?.showDefaultAlert(message: error.description)
            }).disposed(by: disposeBag)
        
        output?.isCreating$
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: {[weak self] isCreating in
                    
                if(isCreating){
                    self?.confirmButton.isHidden = true;
                    self?.confirmLoadingView.start()
                    self?.confirmButton.setTitle(nil, for: .normal)
                }
                else{
                    self?.confirmButton.isHidden = false;
                    self?.confirmLoadingView.stop()
                    self?.confirmButton.setTitle(L10n.Common.ok, for: .normal)
                }
            }).disposed(by: disposeBag)
        
        
        output?.isSuccess$
            .subscribe(onNext: { [weak self] isSuccess in
                guard isSuccess == true else { return }
                self?.showDefaultAlert(
                    message: L10n.PlaceModification.success,
                    buttonTitle: L10n.Common.ok,
                    animated: true,
                    completion: nil,
                    handler: self?.handleSuccessionAlertComplete
                )
            })
            .disposed(by: disposeBag)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI();
        setupConstraints();
        setupStyle();
        bindViewModel();
        setupDismissKeyboardOnTap()
    }
    
    init(vm:PlaceModificationBottomSheetViewModelProtocol){
        self.placeModificationBottomSheetViewModel = vm
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}


#if DEBUG
// MARK: - Testing helpers
extension PlaceModificationBottomSheetViewController {
    var test_cancelButton: UIButton { cancelButton }
    var test_confirmButton: UIButton { confirmButton }
    var test_descriptionTextView: UITextView { descriptionTextView }
}
#endif

