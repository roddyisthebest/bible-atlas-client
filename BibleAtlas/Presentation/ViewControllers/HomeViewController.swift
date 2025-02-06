//
//  HomeViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/4/25.
//

import UIKit
import SnapKit

class HomeViewController: UIViewController{
    
    private var moreFetching = false // ✅ 중복 호출 방지

    private var dummyData = ["Apple", "Banana", "Cherry", "Date", "Elderberry"]

    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setTitle()
        setupStyle();
        setupTable();
        setupConstraint();
        setupNavigationBar();
        setupRefreshControl();
    }
    
    
    private func setupConstraint(){
        view.addSubview(tableView);
        
        tableView.snp.makeConstraints{make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.bottom.equalToSuperview().inset(10)
        }
    }
    
    private func setupTable(){
        tableView.register(ActivityCell.self, forCellReuseIdentifier: ActivityCell.identifier)
        tableView.dataSource = self;
        tableView.delegate = self;
    }
    
    private func setTitle(titleText:String = "활동(300)"){
        navigationItem.title = titleText
    }
    
    private func setupStyle(){
        view.backgroundColor = .tabbarGray

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
        
        tableView.backgroundColor = .tabbarGray;
    }

    
    private func setupNavigationBar(){
        
        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus.circle"),
            style: .plain,
            target: self,
            action: #selector(rightButtonTapped)
        )
        addButton.tintColor = UIColor.white

        navigationItem.rightBarButtonItem = addButton
    }
    
    private func setupRefreshControl(){
        let refreshControl = UIRefreshControl();
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged);
        tableView.refreshControl = refreshControl;
        
    }
  
    @objc private func rightButtonTapped(){
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


extension HomeViewController: UITableViewDataSource{
    
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

extension HomeViewController:UITableViewDelegate {
        
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }

}


extension HomeViewController: UIScrollViewDelegate{
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
