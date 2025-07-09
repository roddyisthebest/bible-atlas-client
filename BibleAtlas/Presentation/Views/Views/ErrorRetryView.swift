//
//  ErrorRetryView.swift
//  BibleAtlas
//
//  Created by 배성연 on 6/1/25.
//

import UIKit
import RxSwift
import RxCocoa

final class ErrorRetryView: UIStackView {
    
    // MARK: - Public
    let refetchTapped$ = PublishRelay<Void>()
    let closeTapped$ = PublishRelay<Void>()

    // MARK: - Private UI
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.text = "에러가 발생했습니다."
        label.textColor = .mainLabelText
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 5;
        
      
        
        return label
    }()
    
    private let refetchButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .mainText

        let icon = UIImage(systemName: "arrow.clockwise")
        button.setImage(icon, for: .normal)
        button.setTitle("다시 불러오기", for: .normal)
        button.setTitleColor(.invertedMainText, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 14)
        button.tintColor = .invertedMainText

        // ⬇️ 아이콘과 텍스트 간격 조절
        button.semanticContentAttribute = .forceLeftToRight
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)

        // ⬇️ 버튼 내부 여백
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

        // ⬇️ 라운드
        button.layer.cornerRadius = 8
        button.clipsToBounds = true

        return button
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .mainText

        let icon = UIImage(systemName: "xmark")
        button.setImage(icon, for: .normal)
        button.setTitle("닫기", for: .normal)
        button.setTitleColor(.invertedMainText, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 14)
        button.tintColor = .invertedMainText

        // ⬇️ 간격 조절
        button.semanticContentAttribute = .forceLeftToRight
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)

        // ⬇️ 여백 및 라운드
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        button.layer.cornerRadius = 8
        button.clipsToBounds = true

        return button
    }()
    
    private let disposeBag = DisposeBag()
    

    
    // MARK: - Init
    init(frame: CGRect = .zero, closable: Bool = false) {
        super.init(frame: frame)
        setup()
        setupConstraints()
        bind()
        
        if(!closable){
            self.closeButton.isHidden = true
        }
        
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
        setupConstraints();
        bind()
    }
    
    // MARK: - Setup
    private func setup() {
        axis = .vertical
        alignment = .center
        distribution = .equalSpacing
        spacing = 10
        isHidden = true
        
        addArrangedSubview(errorLabel)
        addArrangedSubview(refetchButton)
        addArrangedSubview(closeButton)
    }
    
    private func bind() {
        refetchButton.rx.tap
            .bind(to: refetchTapped$)
            .disposed(by: disposeBag)
        
        closeButton.rx.tap
            .bind(to: closeTapped$)
            .disposed(by: disposeBag)
    }
    
    private func setupConstraints(){
        errorLabel.snp.makeConstraints { make in
            make.width.lessThanOrEqualToSuperview().multipliedBy(0.8)
        }
    }
    

    
    func setMessage(_ message: String) {
           errorLabel.text = message
    }
}
