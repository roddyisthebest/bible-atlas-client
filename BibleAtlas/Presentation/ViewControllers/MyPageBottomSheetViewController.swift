//
//  MyPageBottomSheetViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 7/16/25.
//

import UIKit
import RxSwift
import RxRelay

final class MyPageBottomSheetViewController: UIViewController {
    
    private var menuHeight = 60;
    
    private let disposeBag = DisposeBag();
    
    private let avatarImageLength = 50;
    
    private let menuItemCellTapped$ = PublishRelay<MenuItem>();
    
    private lazy var headerStackView = {
        let sv = UIStackView(arrangedSubviews: [userStackView, closeButton]);
        sv.axis = .horizontal;
        sv.distribution = .fillProportionally;
        sv.alignment = .center
        
        return sv;
    }()
        
    private lazy var userStackView = {
        let sv = UIStackView(arrangedSubviews: [userAvatarImageView, userInfoStackView]);
        sv.axis = .horizontal;
        sv.distribution = .fill
        sv.alignment = .fill
        sv.spacing = 14
        return sv;
    }()
    
    private lazy var userInfoStackView = {
        let sv = UIStackView(arrangedSubviews: [nameLabel, emailLabel]);
        sv.axis = .vertical;
        sv.distribution = .fill;
        sv.alignment = .fill

        return sv;
    }()
    
    
    private lazy var userAvatarImageView = {
        let iv = UIImageView();
        iv.contentMode = .scaleAspectFill;
        iv.clipsToBounds = true;
        iv.layer.cornerRadius = CGFloat(avatarImageLength / 2)
    
        return iv;
    }()
    
    private let nameLabel = {
        let label = UILabel();
        label.textColor = .mainText
        label.font = .boldSystemFont(ofSize: 20)
        label.numberOfLines = 1;
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    
    private let emailLabel = {
        let label = UILabel();
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 1;
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
        
    
    private let closeButton = CircleButton(iconSystemName: "xmark");
    
    
    private lazy var menuTableView = {
        let tv = UITableView();
        tv.register(MenuTableViewCell.self, forCellReuseIdentifier: MenuTableViewCell.identifier)
        
        tv.delegate = self;
        tv.dataSource = self;
        
        tv.backgroundColor = .mainItemBkg
        
        tv.layer.cornerRadius = 10;
        tv.layer.masksToBounds = true;

        tv.isScrollEnabled = false
        return tv;
    }()
    
    private var menuItems:[MenuItem] = []

    
    private var myPageBottomSheetViewModel:MyPageBottomSheetViewModelProtocol?
    
    
    init(myPageBottomSheetViewModel: MyPageBottomSheetViewModelProtocol) {
        self.myPageBottomSheetViewModel = myPageBottomSheetViewModel
                
        super.init(nibName: nil, bundle: nil)

    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI();
        setupConstraints();
        setupStyle();
        setupMemuItems()
        bindViewModel();
    }
    
    override func viewDidLayoutSubviews() {
        let menuLength = max(menuItems.count, 1)
        menuHeight = Int(menuTableView.bounds.height) / menuLength
    }
    
    private func setupMemuItems(){
        menuItems = self.myPageBottomSheetViewModel?.menuItems ?? []
        
        menuTableView.reloadData();
    }
    
    private func setupStyle(){
        view.backgroundColor = .mainBkg
    }
    
    private func setupUI(){
        view.addSubview(headerStackView)
        view.addSubview(menuTableView)
    }
    
    private func setupConstraints(){
        
        headerStackView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().inset(20)
        }
        
        menuTableView.snp.makeConstraints { make in
            make.top.equalTo(headerStackView.snp.bottom).offset(20);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
            make.bottom.equalToSuperview().inset(20)
        }
        
        userAvatarImageView.snp.makeConstraints { make in
            make.height.width.equalTo(avatarImageLength)
        }
    }
    
    private func bindViewModel(){
        let closeButtonTapped$ = closeButton.rx.tap.asObservable();
        
        let output = myPageBottomSheetViewModel?.transform(input: MyPageBottomSheetViewModel.Input(closeButtonTapped$: closeButtonTapped$.asObservable(), menuItemCellTapped$: menuItemCellTapped$.asObservable()))
        
        output?.profile$.bind{ [weak self] profile in
            
            
            guard let profile = profile else {
                return
            }
            self?.setAvatarImage(urlString: profile.avatar)
            self?.nameLabel.text = profile.name ?? "아무개"
            self?.emailLabel.text = profile.email
            
        }.disposed(by: disposeBag)
        
    }
    
    
    private func setAvatarImage(urlString: String) {
        let replaced = urlString.replacingOccurrences(of: "svg", with: "png")
        guard let url = URL(string: replaced) else { return }
        
        userAvatarImageView.kf.setImage(
            with: url,
            options: [
                .transition(.fade(0.2))
            ],
            completionHandler: { result in
                switch result {
                case .success(let value):
                    print("✅ Avatar image loaded: \(value.source.url?.absoluteString ?? "")")
                case .failure(let error):
                    print("❌ Avatar image load failed: \(error.localizedDescription)")
                }
            }
        )

    }
    

}


extension MyPageBottomSheetViewController:  UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MenuTableViewCell.identifier, for: indexPath) as? MenuTableViewCell else {
            return UITableViewCell()
        }
        
        cell.setMenu(menuItem: menuItems[indexPath.row])
        
        if indexPath.row == menuItems.count - 1 {
               cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.width, bottom: 0, right: 0)
           } else {
               cell.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        }
        return cell

    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(menuHeight);
    }
    
    
}

extension MyPageBottomSheetViewController:UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        menuItemCellTapped$.accept(menuItems[indexPath.row])
        
    }
    
}
