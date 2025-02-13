//
//  SortSelectionViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/13/25.
//

import UIKit

class SortSelectionViewController: UIViewController {
    private let options = ["최신순", "인기순", "이름순"]
    
    // ✅ 선택된 값을 전달하는 클로저
    var didSelectOption: ((String) -> Void)?
    
    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupTableView()
    }

    private func setupTableView() {
        tableView.frame = view.bounds
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
    }
}

// ✅ UITableView 데이터 전달 로직
extension SortSelectionViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = options[indexPath.row]
        cell.textLabel?.textAlignment = .center
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedOption = options[indexPath.row]
        didSelectOption?(selectedOption)  // ✅ 선택한 값을 클로저를 통해 전달
        dismiss(animated: true)
    }
}
