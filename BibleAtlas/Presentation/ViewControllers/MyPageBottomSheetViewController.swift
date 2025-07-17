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
    
    private let disposeBag = DisposeBag();
    
    private let avatarImageLength = 50;
    
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
        sv.spacing = 8
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
        tv.register(PlaceTableViewCell.self, forCellReuseIdentifier: PlaceTableViewCell.identifier)
        
        tv.delegate = self;
        tv.dataSource = self;
        
        tv.backgroundColor = .mainItemBkg
        
        tv.layer.cornerRadius = 10;
        tv.layer.masksToBounds = true;
        tv.rowHeight = 80;
        
 
        
        return tv;
    }()
    
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
        bindViewModel();
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
        
        let output = myPageBottomSheetViewModel?.transform(input: MyPageBottomSheetViewModel.Input(closeButtonTapped$: closeButtonTapped$.asObservable()))
        
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


extension MyPageBottomSheetViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        guard let cell = tableView.dequeueReusableCell(withIdentifier: PlaceTableViewCell.identifier, for: indexPath) as? PlaceTableViewCell else {
//            return UITableViewCell()
//        }
//        
        return UITableViewCell()

    }
}
