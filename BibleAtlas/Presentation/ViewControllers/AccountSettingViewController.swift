//
//  AccountSettingViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/11/25.
//

import UIKit

final class AccountSettingViewController: UIViewController {
    
    private lazy var titleView = {
        let view = UIView();
        view.addSubview(backButton);
        view.addSubview(titleLabel);
        return view;
    }();
    private let tableView = UITableView(frame:.zero,style:.plain)
    
    
    private lazy var backButton:UIButton = {
        let button = UIButton();
        
        let icon = UIImage(systemName: "xmark");
        button.setImage(icon, for: .normal);
        button.imageView?.contentMode = .scaleAspectFit;
        button.tintColor = .white;
        button.addTarget(self, action: #selector(backbuttonTapped), for: .touchUpInside)
        return button;
    }();
 
    
    private let titleLabel = {
        let label = UILabel();
        label.text = "설정"
        label.font = .boldSystemFont(ofSize: 22)
        label.textColor = .white;
        return label;
    }()
    
    
    private let sections: [(title: String, showArrow: Bool, detailText: String?, isDestructive: Bool)] = [
        ("고객센터 문의하기", true, nil, false),
        ("프로필 수정", true, nil, false),
        ("이용약관", true, nil, false),
        ("앱 버전", false, "1.0.0", false),
        ("로그아웃", false, nil, false),
        ("회원 탈퇴", false, nil, true)
    ]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar();
        setupUI();
        setupConstraint()
        setupStyle();

    }
    
    
    private func setupStyle(){
        view.backgroundColor = .tabbarGray
        tableView.backgroundColor = .tabbarGray;
    }
    
    private func setupNavigationBar(){
        navigationItem.title = "계정관리"
    }
    
    private func setupUI(){
        
        view.addSubview(titleView);
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(AccountSettingCell.self, forCellReuseIdentifier: AccountSettingCell.identifier)
    }
    
    private func setupConstraint(){
        
        titleView.snp.makeConstraints{make in
            make.top.equalTo(view.safeAreaLayoutGuide);
            make.leading.trailing.equalToSuperview().inset(10);
            make.height.equalTo(30)
        }
        
        backButton.snp.makeConstraints{make in
            make.height.equalTo(22);
            make.width.equalTo(22);
            make.leading.equalToSuperview().offset(10);
            make.centerY.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints{make in
            make.leading.equalTo(backButton.snp.trailing).offset(10);
            make.centerY.equalToSuperview()
        }
        
        tableView.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview();
            make.top.equalTo(titleView.snp.bottom).offset(10)
         }
    }

    
    @objc private func backbuttonTapped(){
        dismiss(animated: true)
    }

}

extension AccountSettingViewController: UITableViewDataSource{

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AccountSettingCell.identifier, for: indexPath) as? AccountSettingCell else {
            return UITableViewCell()
        }
            
        let item = sections[indexPath.row];
        cell.configure(title: item.title, showArrow: item.showArrow, detailText: item.detailText, isDestructive: item.isDestructive)
        cell.selectionStyle = .none

        return cell;
    }
    
    
    
    
    
}


extension AccountSettingViewController:UITableViewDelegate {
        
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

}
