//
//  DeleteVoteViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/24/25.
//

import UIKit
import SnapKit
final class DeleteVoteViewController: UIViewController {

    private lazy var containerView = {
        let uv = UIView();
        uv.backgroundColor = .wrapperGray;
        uv.layer.cornerRadius = 8;
        uv.addSubview(titleStackView)
        uv.addSubview(contentStackView)

        view.addSubview(uv)
        return uv;
    }();
    
    
    private lazy var locationCard = {
        let card = LocationCard(title: "안녕", description: "ㅁㄴㅇㄴㅇㄴㅇㄴ");
        view.addSubview(card)
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
        label.text = "추가 코멘트"
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
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupNavigationBar(){
        navigationItem.title = "데이터 삭제 요청";
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "저장", style: .plain, target: self, action: #selector(saveButtonTapped))
    }
    
    private func setupStyle(){
        view.backgroundColor = .tabbarGray;
    }
    
    private func setupConstraints(){
        
        locationCard.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
            contentFieldHeightConstraint = make.top.equalTo(view.safeAreaLayoutGuide).offset(20);

        }
        containerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
            make.top.equalTo(locationCard.snp.bottom).offset(20);

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
            make.bottom.equalToSuperview().inset(20)
        }
        
        contentField.snp.makeConstraints{make in
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


extension DeleteVoteViewController: UITextViewDelegate{
    func textViewDidBeginEditing(_ textView: UITextView) {
        DispatchQueue.main.async{
            self.contentFieldHeightConstraint?.constraint.update(offset: -110)
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }

    }

    func textViewDidEndEditing(_ textView: UITextView) {
        DispatchQueue.main.async{
            self.contentFieldHeightConstraint?.constraint.update(offset: 20)
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
            
        }
        
    }
}
