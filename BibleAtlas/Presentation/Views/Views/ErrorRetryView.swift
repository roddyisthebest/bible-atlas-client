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
    
    // MARK: - Private UI
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.text = "에러가 발생했습니다."
        label.textColor = .mainLabelText
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        return label
    }()
    
    private let refetchButton: UIButton = {
        let button = UIButton(type: .system)
        let icon = UIImage(systemName: "arrow.clockwise")
        button.setImage(icon, for: .normal)
        button.setTitle("다시 불러오기", for: .normal)
        button.setTitleColor(.mainLabelText, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 14)
        button.tintColor = .mainLabelText
        return button
    }()
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        bind()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
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
    }
    
    private func bind() {
        refetchButton.rx.tap
            .bind(to: refetchTapped$)
            .disposed(by: disposeBag)
    }
    
    func setMessage(_ message: String) {
           errorLabel.text = message
    }
}
