//
//  CreateVoteViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/20/25.
//

import UIKit

class CreateVoteViewController: UIViewController {
    
    private lazy var containerView = {
        let uv = UIView();
        uv.backgroundColor = .lightGray;
        uv.layer.cornerRadius = 8;
        uv.addSubview(titleStackView)
        uv.addSubview(contentStackView)
        uv.addSubview(locationStackView)

        view.addSubview(uv)
        return uv;
    }();
    
    

    
    
    private lazy var titleStackView = {
        let sv = UIStackView(arrangedSubviews: [titleLabel, titleField]);
        sv.axis = .vertical;
        sv.spacing = 15;
        sv.alignment = .fill;
        sv.distribution = .fill;
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
        textField.borderStyle = .roundedRect
        textField.placeholder = "이름을 입력하세요"
        textField.backgroundColor = .thirdGray;
        return textField
    }()
    
    
    private lazy var contentStackView = {
        let sv = UIStackView(arrangedSubviews: [contentLabel, contentField]);
        sv.axis = .vertical;
        sv.spacing = 15;
        sv.alignment = .fill;
        sv.distribution = .fill;
        return sv;
    }();
    
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.text = "내용"
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .white
        return label
    }()
    
    private let contentField: UITextView = {
        let textView = UITextView()
        textView.layer.cornerRadius = 8;

        textView.backgroundColor = .thirdGray;
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 8, bottom: 16, right: 8) // 내부 패딩 설정
        textView.tintColor = .white
        textView.textColor = .white

        return textView
    }()
    
    private lazy var locationStackView = {
        let sv = UIStackView(arrangedSubviews: [locationLabel, locationSelectView]);
        sv.axis = .vertical;
        sv.spacing = 15;
        sv.alignment = .fill;
        sv.distribution = .fill;
        return sv;
    }();
    
    
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.text = "위치"
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .white
        return label
    }()
    
    private lazy var locationSelectView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8;
        view.backgroundColor = .clear;
        view.addSubview(locationButton)
        return view
    }()
    
    private lazy var locationButton:UIButton = {
        let button = UIButton();
        button.backgroundColor = .lightestGray
        button.layer.cornerRadius = 8;
        button.addSubview(locationButtonInnerStackView)
        return button;
    }()
    
    private lazy var locationButtonInnerStackView: UIStackView = {
        let topSpacer = UIView()
        let bottomSpacer = UIView()
        
        let sv = UIStackView(arrangedSubviews: [topSpacer, locationButtonIcon, locationButtonLabel, bottomSpacer])
        sv.axis = .vertical
        sv.alignment = .center // ✅ 가로 중앙 정렬
        sv.distribution = .equalSpacing // ✅ 세로 중앙 정렬 (빈 뷰 활용)
        sv.spacing = 10
        return sv
    }()

    
    private let locationButtonIcon:UIImageView = {
        let image = UIImage(systemName: "location.north.circle.fill")
        let icon = UIImageView(image:image);
        icon.tintColor = .thirdGray
        return icon;
    }()
    
    private let locationButtonLabel:UILabel = {
        let label = UILabel();
        label.text = "새로운 위치를 선택해주세요."
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .thirdGray;
        return label;
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupStyle();
        setupConstraints();
        setupNavigationBar();

        // Do any additional setup after loading the view.
    }
    
    private func setupNavigationBar(){
        navigationItem.title = "데이터 생성 요청";
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "저장", style: .plain, target: self, action: #selector(saveButtonTapped))
    }
    
    private func setupStyle(){
        view.backgroundColor = .thirdGray;
    }
    
    private func setupConstraints(){
        containerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
            make.top.bottom.equalTo(view.safeAreaLayoutGuide);
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
        
        
        locationStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
            make.top.equalTo(contentStackView.snp.bottom).offset(20)
            make.bottom.equalTo(containerView.snp.bottom).inset(20)
        }
        
        locationButton.snp.makeConstraints { make in
            make.top.trailing.leading.equalToSuperview();
            make.height.equalToSuperview().multipliedBy(0.5)
        }

        locationButtonIcon.snp.makeConstraints { make in
            make.height.width.equalTo(40)
        }
        locationButtonInnerStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview();
        }
        
        
    }

    @objc private func saveButtonTapped(){
        
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
