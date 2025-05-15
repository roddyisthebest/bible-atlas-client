//
//  PlaceUpdateBottomSheetViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/11/25.
//

import UIKit

final class PlaceModificationBottomSheetViewController: UIViewController {
    
    private var placeModificationBottomSheetViewModel:PlaceModificationBottomSheetViewModelProtocol?

    private lazy var headerStackView = {
        let sv = UIStackView(arrangedSubviews: [cancelButton, headerLabel, confirmButton]);
        sv.axis = .horizontal;
        sv.distribution = .equalSpacing;
        sv.alignment = .center;
        return sv;
    }()
    
    private let cancelButton = {
        let button = UIButton(type: .system);
        button.setTitle("취소", for: .normal)
        button.setTitleColor(.primaryBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        return button;
    }()
    
    private let headerLabel = {
        let label = HeaderLabel(text: "Request Modification");
        label.font = .boldSystemFont(ofSize: 18);
        return label;
    }()
    
    private let confirmButton = {
        let button = UIButton(type: .system);
        button.setTitle("완료", for: .normal)
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
        tv.text = "인사까지 연습했는데 거기까지 문제 없었는데 왜 니 앞에서면 바보처럼 웃게되 평소처럼만 하면 돼 음 자연스러웟어 우워 안녕안녕"
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
    
    private func bindViewModel(){
        let cancelButtonTapped$ = cancelButton.rx.tap.asObservable();
        
        let confirmButtonTapped$ = confirmButton.rx.tap.asObservable();
            
        let confirmTappedWithText$ = confirmButtonTapped$
            .withLatestFrom(descriptionTextView.rx.text.orEmpty)
 
        placeModificationBottomSheetViewModel?.transform(input: PlaceModificationBottomSheetViewModel.Input(cancelButtonTapped$: cancelButtonTapped$, confirmButtonTapped$: confirmTappedWithText$))
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI();
        setupConstraints();
        setupStyle();
        bindViewModel();
    }
    
    init(vm:PlaceModificationBottomSheetViewModelProtocol){
        self.placeModificationBottomSheetViewModel = vm
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
