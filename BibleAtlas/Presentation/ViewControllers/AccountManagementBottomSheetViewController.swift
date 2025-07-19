//
//  AccountManagementBottomSheetViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 7/19/25.
//

import UIKit
import RxSwift
import RxRelay

final class AccountManagementBottomSheetViewController: UIViewController {

    private var menuHeight = 60;
    
    private var menuItems:[SimpleMenuItem] = []

    private let disposeBag = DisposeBag();
    
    private let menuItemCellTapped$ = PublishRelay<SimpleMenuItem>();
    
    private let accountManagementBottomSheetViewModel:AccountManagementBottomSheetViewModelProtocol?
    
    private lazy var headerStackView = {
        let sv = UIStackView(arrangedSubviews: [headerLabel, closeButton]);
        sv.axis = .horizontal;
        sv.distribution = .fillProportionally;
        sv.alignment = .center
        
        return sv;
    }()
    
    private let headerLabel = HeaderLabel(text: "Account Settings");
    
    private let closeButton = CircleButton(iconSystemName: "xmark")
    
    private lazy var tableView = {
        let tv = UITableView();
        tv.register(SimpleMenuTableViewCell.self, forCellReuseIdentifier: SimpleMenuTableViewCell.identifier)
        
        tv.delegate = self;
        tv.dataSource = self;
        
        tv.backgroundColor = .mainItemBkg
        tv.layer.cornerRadius = 10;
        tv.layer.masksToBounds = true;
        
        tv.isScrollEnabled = false
        
        
        
        return tv;
    }()
    
    
    
    
    
    init(accountManagementBottomSheetViewModel: AccountManagementBottomSheetViewModelProtocol) {
        self.accountManagementBottomSheetViewModel = accountManagementBottomSheetViewModel
                
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
        setupMenuItems();
        bindViewModel();
        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
        
        tableView.snp.makeConstraints { make in
            make.height.equalTo(menuHeight * menuItems.count)
        }
        
    }
    
    
    private func setupUI(){
        view.addSubview(headerStackView);
        view.addSubview(tableView);

    }
    
    private func setupStyle(){
        view.backgroundColor = .mainBkg;
    }
    
    private func bindViewModel(){
        
        let closeButtonTapped$ = closeButton.rx.tap.asObservable();
        
        let output = accountManagementBottomSheetViewModel?.transform(input: AccountManagementBottomSheetViewModel.Input(closeButtonTapped$: closeButtonTapped$.asObservable(), menuItemCellTapped$: menuItemCellTapped$.asObservable()))
        
        
        output?.profile$.bind{ [weak self]
            profile in
            
            guard let profile = profile else {
                return
            }
            
            
        }.disposed(by: disposeBag)
        
        
        output?.withdrawalButtonTapped$.bind{[weak self] in
            self?.showWithdrawalAlert();
            
        }.disposed(by: disposeBag)
    }
    
    private func showWithdrawalAlert() {
        let alert = UIAlertController(
            title: "정말 탈퇴하시겠어요?",
            message: "회원 정보를 포함한 모든 데이터가 삭제됩니다.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        
        alert.addAction(UIAlertAction(title: "탈퇴", style: .destructive) { [weak self] _ in
                // TODO: 탈퇴 로직 처리 vm에 전달 필요
        })
        
        present(alert, animated: true)
    }
    
    
    
    private func setupMenuItems(){
        menuItems = self.accountManagementBottomSheetViewModel?.menuItems ?? [];
        tableView.reloadData();
    }
    
    private func setupConstraints(){
        headerStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);
            make.height.equalTo(44)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerStackView.snp.bottom).offset(20);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);
            make.bottom.lessThanOrEqualToSuperview().inset(20);
            
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


extension AccountManagementBottomSheetViewController:UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SimpleMenuTableViewCell.identifier, for: indexPath) as? SimpleMenuTableViewCell else {
            return UITableViewCell()
        }
        
        cell.setMenu(menuItem: menuItems[indexPath.row])
        
        if indexPath.row == menuItems.count - 1 {
               cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.width, bottom: 0, right: 0)
           } else {
               cell.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        }
        
        
        return cell;
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(menuHeight);
    }
    
    
    
}


extension AccountManagementBottomSheetViewController:UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let menuItem = menuItems[indexPath.row]
        menuItemCellTapped$.accept(menuItem)
        
        
    }
    
}
