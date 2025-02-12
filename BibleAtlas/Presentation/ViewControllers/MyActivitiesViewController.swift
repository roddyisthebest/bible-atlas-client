//
//  MyActivitiesViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/12/25.
//

import UIKit

final class MyActivitiesViewController: UIViewController {

    private var moreFetching = false

    private var dummyData = ["Apple", "Banana", "Cherry", "Date", "Elderberry"]

    private let tableView = UITableView()
    
    private lazy var navigationBar: UINavigationBar = {
        let navBar = UINavigationBar()
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .thirdGray
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
         
        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        
        
        let navItem = UINavigationItem(title: "내 활동기록")
        
        let backButton = UIButton(type: .system)
        backButton.setTitle("Back", for: .normal)
        backButton.setTitleColor(.systemBlue, for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        
        let boldConfig = UIImage.SymbolConfiguration(weight: .bold)
        let backImage = UIImage(systemName: "chevron.left", withConfiguration: boldConfig)
        backButton.setImage(backImage, for: .normal)
        
        backButton.tintColor = .systemBlue
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)

        backButton.contentHorizontalAlignment = .left
        backButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 5)

        let backBarButtonItem = UIBarButtonItem(customView: backButton) // ✅ 커스텀 뷰 적용
        navItem.leftBarButtonItem = backBarButtonItem
        navBar.setItems([navItem], animated: false)
        return navBar
     }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupStyle();
        setupNavigationBar();
        setupTable();
        setupConstraint();
        setupRefreshControl();
        
    }
    
    private func setupNavigationBar(){
        view.addSubview(navigationBar);
    }
    
    
    

    private func setupConstraint(){

        navigationBar.snp.makeConstraints{ make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide);
            make.height.equalTo(40)
        }
        
        
        
        tableView.snp.makeConstraints{make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom)
        }
        
        
        
    }
    
    private func setupTable(){
        view.addSubview(tableView);
        tableView.register(ActivityCell.self, forCellReuseIdentifier: ActivityCell.identifier)
        tableView.dataSource = self;
        tableView.delegate = self;
    }
    

    
    private func setupStyle(){
        view.backgroundColor = .thirdGray

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.thirdGray
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
        ]

        if let navigationBar = navigationController?.navigationBar {
           navigationBar.standardAppearance = appearance
           navigationBar.scrollEdgeAppearance = appearance
        }
        
        tableView.backgroundColor = .thirdGray;
    }

    

    
    
    private func setupRefreshControl(){
        let refreshControl = UIRefreshControl();
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged);
        tableView.refreshControl = refreshControl;
        
    }
  
    @objc private func rightButtonTapped(){
    }
    
    @objc private func backButtonTapped(){
        let transition = CATransition();
        
        transition.duration = 0.3;
        
        transition.type = .push;
        transition.subtype = .fromLeft;
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
 
        view.window?.layer.add(transition, forKey: kCATransition)
        
        dismiss(animated: false)
    }
    
    
    private func resetData(){
        dummyData = ["Apple", "Banana", "Cherry", "Date", "Elderberry"]
    }
    
    private func loadMoreData(){
        guard !moreFetching else { return }
        moreFetching = true;
        
        DispatchQueue.global().async{
            
            let newData = ["Item \( self.dummyData.count + 1)", "Item \(self.dummyData.count + 2)"]
            self.dummyData.append(contentsOf: newData)
            
            
            DispatchQueue.main.async{
                self.tableView.reloadData();
                self.moreFetching = false
            }
        }
    }
    
    @objc private func refreshData(){
        guard !moreFetching else { return }
        
        DispatchQueue.global().async{
            self.resetData();
        
            DispatchQueue.main.asyncAfter(deadline:.now() + 1.5){
                self.tableView.reloadData();
                self.tableView.refreshControl?.endRefreshing();
            }
        }
        
    }

}



extension MyActivitiesViewController: UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dummyData.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ActivityCell.identifier , for: indexPath) as? ActivityCell else {
            return  UITableViewCell()
        }
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        return cell;
    }
}

extension MyActivitiesViewController:UITableViewDelegate {
        
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }

}


extension MyActivitiesViewController: UIScrollViewDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
           let offsetY = scrollView.contentOffset.y
           let contentHeight = scrollView.contentSize.height
           let frameHeight = scrollView.frame.size.height
           
           // ✅ 스크롤이 제일 밑에 도달했을 때 실행
           if offsetY + frameHeight >= contentHeight - 10 { // 약간의 여유 (10px)
               loadMoreData()
           }
       }
}
