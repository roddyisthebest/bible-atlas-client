//
//  HomeBottomSheetViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/19/25.
//

import UIKit
import RxSwift
import RxCocoa

final class HomeBottomSheetViewController: UIViewController{
    
    private var homeBottomSheetViewModel:HomeBottomSheetViewModelProtocol?
 
    private let homeContentViewController: HomeContentViewController
    private let searchReadyViewController: SearchReadyViewController
    private let searchResultViewController: SearchResultViewController
    
    
    
    private let disposeBag = DisposeBag()
    
    private lazy var bodyView = {
        let v = UIView();
        v.addSubview(headerStackView);
    
        return v;
    }()
    
    private lazy var headerStackView = {
        let sv = UIStackView(arrangedSubviews: [searchTextField, userAvatarButton, cancelButton]);
        
        sv.axis = .horizontal;
        sv.spacing = 10;
        sv.distribution = .fill;
        sv.alignment = .fill;
        
        return sv;
    }()
    
    private lazy var searchTextField: UISearchTextField = {
        let input = UISearchTextField()
        
        input.delegate = self;
        input.placeholder = "search places..."
        
        input.font = .systemFont(ofSize: 16)
        
        input.returnKeyType =  .done
        
        input.autocorrectionType = .no
        input.spellCheckingType = .no
        input.translatesAutoresizingMaskIntoConstraints = false
        
        return input
    }()
    
    
    
    private lazy var userAvatarButton = {
        let button = UIButton(type: .system)
        
        button.backgroundColor = .userAvatarBkg;
        button.layer.cornerRadius = 20;
        button.layer.masksToBounds = true;
        button.setTitle("로그인", for: .normal)
        
        button.setTitleColor(.primaryBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
 
        
        return button;
    }()
    
    private let cancelButton = {
        let button =  UIButton(type: .system)
            
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.primaryBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)

        button.isHidden = true
        return button;
    }()
    
    
    private let lowDetent = UISheetPresentationController.Detent.custom { context in
        return UIScreen.main.bounds.height * 0.2;
    }
    

    private func setupUI(){
        view.addSubview(bodyView);
    }
    
    
    
    private func bindViewModel(){
        let cancelButtonTapped$ = cancelButton.rx.tap.asObservable();
        
        let editingDidBegin$ = searchTextField.rx.controlEvent(.editingDidBegin).asObservable()
        
        let avatarButtonTapped$ = userAvatarButton.rx.tap.asObservable();
 
        let output = homeBottomSheetViewModel?.transform(input: HomeBottomSheetViewModel.Input(avatarButtonTapped$: avatarButtonTapped$.asObservable(), cancelButtonTapped$: cancelButtonTapped$.asObservable(), editingDidBegin$: editingDidBegin$.asObservable()))
        
        
        searchTextField.rx.text.orEmpty
            .subscribe(onNext: { output!.keyword$.accept($0) })
            .disposed(by: disposeBag)
        
        output!.keywordText$
            .drive(searchTextField.rx.text)
            .disposed(by: disposeBag)
        
        
        output?.isSearchingMode$
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: {[weak self] isSearchingMode in
                guard let self = self, let sheet = self.sheetPresentationController else { return }
                     if isSearchingMode {
                         UIView.animate(withDuration: 0.3) {
                             sheet.animateChanges {
                                 sheet.selectedDetentIdentifier = .large
                             }
                            
                         }
                  
                         
                         sheet.detents = [.large()]
       
                         
                     } else {

                         sheet.detents = [.large(), .medium(), lowDetent]
                         
                         
                         self.searchTextField.resignFirstResponder()
                         UIView.animate(withDuration: 0.3) {
                             sheet.animateChanges {
                                 sheet.selectedDetentIdentifier = .medium
                             }
                         }
                         
                     }
                
            })
            .disposed(by: disposeBag)
        
        output?.screenMode$
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] mode in
                guard let self = self else { return }
                switch mode {
                case .home:
                    self.swapToChildVC(self.homeContentViewController)
                    self.userAvatarButton.isHidden = false;
                    self.cancelButton.isHidden = true
                case .searchReady:
                    self.swapToChildVC(self.searchReadyViewController)
                    self.userAvatarButton.isHidden = true;
                    self.cancelButton.isHidden = false;
                case .searching:
                    self.swapToChildVC(self.searchResultViewController)
                    self.userAvatarButton.isHidden = true;
                    self.cancelButton.isHidden = false;
                }
            })
            .disposed(by: disposeBag)
        

        
        Observable
            .combineLatest(output!.isLoggedIn$, output!.profile$)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoggedIn, profile in
                
                if isLoggedIn {
                    
                    guard let profile = profile else {
                        return
                    }
                    self?.userAvatarButton.setTitle(profile.name ?? "shy", for: .normal)
                    return
                }
                
                self?.userAvatarButton.setTitle("로그인", for: .normal)
                
            })
            .disposed(by: disposeBag)
        
        
    }
 
    init(
        homeBottomSheetViewModel: HomeBottomSheetViewModelProtocol,
        homeContentViewController: HomeContentViewController,
        searchReadyViewController: SearchReadyViewController,
        searchResultViewController: SearchResultViewController
    ) {
        self.homeBottomSheetViewModel = homeBottomSheetViewModel
        self.homeContentViewController = homeContentViewController
        self.searchReadyViewController = searchReadyViewController
        self.searchResultViewController = searchResultViewController
        super.init(nibName: nil, bundle: nil)
    }
    
   
    

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI();
        setupStyle();
        setupConstraints();
        setupSheet();
        bindViewModel()
        setupDismissKeyboardOnTap();
    }
    

    private func swapToChildVC(_ newVC: UIViewController) {
        children.forEach {
            $0.willMove(toParent: nil)
            $0.view.removeFromSuperview()
            $0.removeFromParent()
        }

        addChild(newVC)
        view.insertSubview(newVC.view, belowSubview: headerStackView)
        newVC.view.snp.makeConstraints { make in
            make.top.equalTo(headerStackView.snp.bottom).offset(0)
            make.leading.trailing.bottom.equalToSuperview()
        }
        newVC.didMove(toParent: self)
    }
    
    
    private func setupSheet(){
//        if let sheet = self.sheetPresentationController {
//            sheet.delegate = self
//        }
    }
    
    
    
    private func setupStyle(){
        view.backgroundColor = .mainBkg;
    }
    
    private func setupConstraints(){
        bodyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        
        headerStackView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);
            make.height.equalTo(40);
        }
        
        userAvatarButton.snp.makeConstraints { make in
            make.width.equalTo(40);
        }
        
        
    }
    
}



//extension HomeBottomSheetViewController:UISheetPresentationControllerDelegate{
//    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
//          let isLarge = sheetPresentationController.selectedDetentIdentifier == .large
//        homeScrollView.isScrollEnabled = isLarge
//      }
//}


extension HomeBottomSheetViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}





