import UIKit
import SnapKit

final class SearchViewController: UIViewController {
    
    private let tableView = {
        let tv = UITableView();
        tv.backgroundColor = .backgroundDark
        tv.separatorStyle = .singleLine
        tv.separatorColor = .lightGray
        return tv;
    }()
    
    private let backButton = {
        let button =  UIButton();
        button.setImage(UIImage(systemName: "chevron.left"),for:.normal)
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button;
    }();
    
    private let searchTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Search..."
        textField.backgroundColor = .thirdGray
        textField.textColor = .white // 텍스트 색상 설정 (필요 시)
        textField.borderStyle = .roundedRect // UI 스타일 적용
        return textField
    }()
    
    private lazy var searchContainer = {
        let container = UIView();
        container.addSubview(backButton)
        container.addSubview(searchTextField)

        return container
    }();
    
    
    
    private var data = ["Apple", "Banana", "Cherry", "Date", "Fig", "Grapes"] // 더미 데이터
    private var filteredData: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        filteredData = data  // 초기 데이터 설정
        setupUI();
        setupSearchBar()
        setupTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        activateTextField()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true) // 화면 터치 시 키보드 내리기
    }

    
    private func setupSearchBar() {
        searchTextField.delegate = self
        
        searchContainer.snp.makeConstraints{make in
            make.top.trailing.leading.equalTo(view.safeAreaLayoutGuide);
            make.height.equalTo(50)
            
        }
        
        backButton.snp.makeConstraints{make in
            make.height.width.equalTo(30)
            make.leading.equalToSuperview().offset(20);
            make.centerY.equalToSuperview();
        }
        searchTextField.snp.makeConstraints{make in

            make.leading.equalTo(backButton.snp.trailing).offset(10)
            make.trailing.equalToSuperview().inset(20);
            make.height.equalTo(40);
            make.centerY.equalToSuperview();
        }
    }
    
    private func setupTableView() {
        tableView.frame = view.bounds
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(SearchCell.self, forCellReuseIdentifier: SearchCell.identifier)
        
        tableView.snp.makeConstraints{make in
            make.leading.trailing.equalToSuperview();
            make.bottom.equalToSuperview();
            make.top.equalTo(searchContainer.snp.bottom)
        }
        
    }
    
    private func setupUI(){
        view.addSubview(searchContainer)
        view.addSubview(tableView)
        view.backgroundColor = .backgroundDark
    }
    
    private func activateTextField(){
        searchTextField.becomeFirstResponder()
    }
    
    
    @objc private func backButtonTapped(){
        dismiss(animated: false)
    }
    

    
}

extension SearchViewController:UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchCell.identifier , for: indexPath) as? SearchCell else {
            return  UITableViewCell()
        }
        
        cell.configure(keyword: filteredData[indexPath.row])
    
        return cell
    }
}



extension SearchViewController:UITextFieldDelegate{
    
}


extension SearchViewController:UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}
