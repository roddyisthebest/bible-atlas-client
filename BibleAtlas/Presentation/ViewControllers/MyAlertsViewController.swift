//
//  MyAlertsViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/12/25.
//
//MyAlertsViewController
import UIKit

final class MyAlertsViewController: UIViewController {

    private var moreFetching = false
    private var dummyData = ["Apple", "Banana", "Cherry", "Date", "Elderberry","Apple", "Banana", "Cherry", "Date", "Elderberry"]
    
    private let tableView = UITableView()

    private lazy var filterWrapperView: UIView = {
        let wrapperView = UIView()
        wrapperView.backgroundColor = .thirdGray
   
        wrapperView.addSubview(sortButton)

        return wrapperView
    }()

    private let sortButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .tabbarGray
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.setTitle("정렬기준", for: .normal)
        
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        button.setImage(UIImage(systemName: "chevron.down"),for:.normal);
        button.tintColor = .white;
        button.imageView?.contentMode = .scaleAspectFit;
        
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 5)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: -5)
        
       
        button.titleLabel?.font = .boldSystemFont(ofSize: 14);
        return button
    }()

    private let sortButton2: UIButton = {
        let button = UIButton()
        button.backgroundColor = .tabbarGray
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.setTitle("여름엔덥게", for: .normal)
        
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)  // ✨ 너비를 자동 조정하도록 설정
        button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)  // ✨ 내용이 줄어들지 않도록 설정
        
       
        return button
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupStyle()
        setupTable()
        setupConstraints()
        setupRefreshControl()
        setupNavigationBar()
    }

    private func setupUI() {
        view.addSubview(filterWrapperView)
        view.addSubview(tableView)
    }

    private func setupConstraints() {
        filterWrapperView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(20);
            make.top.equalTo(view.safeAreaLayoutGuide).offset(5)
            make.height.equalTo(50)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(filterWrapperView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        
        sortButton.snp.makeConstraints{ make in
            make.leading.equalToSuperview();
            make.centerY.equalToSuperview();
        }
        
    }

    private func setupTable() {
        tableView.register(AlertCell.self, forCellReuseIdentifier: AlertCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
    }

    private func setupNavigationBar() {
        navigationItem.title = "내 알림"
    }

    private func setupStyle() {
        view.backgroundColor = .thirdGray
        tableView.backgroundColor = .thirdGray
    }

    private func setupRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

    

    @objc private func refreshData() {
        guard !moreFetching else { return }

        DispatchQueue.global().async {
            self.resetData()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.tableView.reloadData()
                self.tableView.refreshControl?.endRefreshing()
            }
        }
    }

    private func resetData() {
        dummyData = ["Apple", "Banana", "Cherry", "Date", "Elderberry","Apple", "Banana", "Cherry", "Date", "Elderberry"]
    }

    private func loadMoreData() {
        guard !moreFetching else { return }
        moreFetching = true

        DispatchQueue.global().async {
            let newData = ["Item \(self.dummyData.count + 1)", "Item \(self.dummyData.count + 2)"]
            self.dummyData.append(contentsOf: newData)

            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.moreFetching = false
            }
        }
    }
}

// ✅ UITableView DataSource & Delegate
extension MyAlertsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dummyData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AlertCell.identifier, for: indexPath) as? AlertCell else {
            return UITableViewCell()
        }
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

// ✅ UIScrollViewDelegate (Infinite Scroll)
extension MyAlertsViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height

        if offsetY + frameHeight >= contentHeight - 10 {
            loadMoreData()
        }
    }
}
