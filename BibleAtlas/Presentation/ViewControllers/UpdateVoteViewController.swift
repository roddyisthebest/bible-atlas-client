//
//  UpdateVoteViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/25/25.
//

import UIKit
import SnapKit
class UpdateVoteViewController: UIViewController {
    private lazy var scrollView = {
        let sv = UIScrollView();

        view.addSubview(sv)
        sv.addSubview(contentView)

        sv.alwaysBounceVertical = true
        sv.showsVerticalScrollIndicator = true
        sv.showsHorizontalScrollIndicator = false
        
        return sv;
    }()
    
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.addSubview(locationCard)
        view.addSubview(containerView)

        return view
    }()
    
    
    private lazy var containerView = {
        let uv = UIView();
        uv.backgroundColor = .wrapperGray;
        uv.layer.cornerRadius = 8;
        uv.addSubview(titleStackView)
        uv.addSubview(contentStackView)
        uv.addSubview(commentStackView)
        return uv;
    }();
    
    
    private lazy var locationCard = {
        let card = LocationCard(title: "안녕", description: "ㅁㄴㅇㄴㅇㄴㅇㄴ");
        return card;
    }();

    
    
    private lazy var titleStackView = {
        let sv = UIStackView(arrangedSubviews: [titleLabel, titleField]);
        sv.axis = .vertical;
        sv.spacing = 15;
        sv.alignment = .fill;
        sv.distribution = .fillProportionally;
        
        return sv;
    }();
    
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "제목"
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .white
        return label
    }()
    
    private let titleField: UITextField = {
        let textField = UITextField()
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.borderStyle = .roundedRect
        textField.placeholder = "이름을 입력하세요"
        textField.backgroundColor = .thirdGray;
        
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        textField.leftViewMode = .always
    
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        textField.rightViewMode = .always
        
        textField.tintColor = .white
        textField.textColor = .white
        return textField
    }()
    
    
    private lazy var contentStackView = {
        let sv = UIStackView(arrangedSubviews: [contentLabel, contentField]);
        sv.axis = .vertical;
        sv.spacing = 15;
        sv.alignment = .fill;
        sv.distribution = .fillProportionally;
        return sv;
    }();
    
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.text = "내용 변경"
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .white
        return label
    }()
    
    private let contentField: UITextView = {
        let textView = UITextView()
        textView.layer.cornerRadius = 8;
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no
        textView.backgroundColor = .thirdGray;
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 8, bottom: 16, right: 8) // 내부 패딩 설정
        textView.tintColor = .white
        textView.textColor = .white
        textView.tag = 1

        return textView
    }()
    
    
    
    private lazy var commentStackView = {
        let sv = UIStackView(arrangedSubviews: [commentLabel, commentField]);
        sv.axis = .vertical;
        sv.spacing = 15;
        sv.alignment = .fill;
        sv.distribution = .fillProportionally;
        return sv;
    }();
    
    
    private let commentLabel: UILabel = {
        let label = UILabel()
        label.text = "추가 코멘트"
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .white
        return label
    }()
    
    private let commentField: UITextView = {
        let textView = UITextView()
        textView.layer.cornerRadius = 8;
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no
        textView.backgroundColor = .thirdGray;
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 8, bottom: 16, right: 8) // 내부 패딩 설정
        textView.tintColor = .white
        textView.textColor = .white
        textView.tag = 2

        return textView
    }()

    private var contentFieldHeightConstraint: ConstraintMakerEditable?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI();
        setupStyle();
        setupConstraints();
        setupNavigationBar();

        

    }
    
    
    private func setupUI(){
        contentField.delegate = self
        commentField.delegate = self

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupNavigationBar(){
        navigationItem.title = "데이터 수정 요청";
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "저장", style: .plain, target: self, action: #selector(saveButtonTapped))
    }
    
    private func setupStyle(){
        view.backgroundColor = .tabbarGray;
    }
    
    private func setupConstraints(){
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide);
        }

        
        contentView.snp.makeConstraints { make in
            make.bottom.trailing.leading.equalTo(scrollView.contentLayoutGuide)
            contentFieldHeightConstraint = make.top.equalTo(scrollView.contentLayoutGuide).offset(0)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        locationCard.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
        }
        
        containerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
            make.top.equalTo(locationCard.snp.bottom).offset(20);
            make.bottom.equalTo(contentView.snp.bottom).inset(20)

        }
        
        titleStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
            make.top.equalToSuperview().offset(20)
        }
    
        
        contentStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
            make.top.equalTo(titleStackView.snp.bottom).offset(20)
        }
        
        contentField.snp.makeConstraints{make in
            make.height.equalTo(250)
        }
        
        commentStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
            make.top.equalTo(contentStackView.snp.bottom).offset(20)
            make.bottom.equalTo(containerView.snp.bottom).inset(20)

        }

        commentField.snp.makeConstraints{make in
            make.height.equalTo(250)
            
        }
        
    }

    @objc private func saveButtonTapped(){
        
    }
    
    @objc private func dismissKeyboard(){
        DispatchQueue.main.async {
            self.view.endEditing(true)
        }
    }

}



extension UpdateVoteViewController: UITextViewDelegate{
    func textViewDidBeginEditing(_ textView: UITextView) {

        DispatchQueue.main.async{
                
            let isContentTextView = textView.tag == 1;
            
            let offset = isContentTextView ? -110: -420;
            
            
            
            self.contentFieldHeightConstraint?.constraint.update(offset: offset)
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }

    }

    func textViewDidEndEditing(_ textView: UITextView) {
        DispatchQueue.main.async{
            self.contentFieldHeightConstraint?.constraint.update(offset: 0)
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
            
        }
        
    }
}
