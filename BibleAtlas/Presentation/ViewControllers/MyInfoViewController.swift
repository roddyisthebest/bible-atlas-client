//
//  MyInfoViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/4/25.
//

import UIKit
import SnapKit
class MyInfoViewController: UIViewController {
        
    
    let safeWrapperView = {
        let view = UIView();
        view.backgroundColor = .tabbarGray;
        return view;
    }();
    
    let headerWrapperView = {
        let view = UIView();
        view.backgroundColor = .lightGray;
        
        return view;
    }();
    
    let headerStackView = {
        let st = UIStackView();

        st.axis = .horizontal;
        st.alignment = .center;
        st.spacing = 10;

        return st;
    }();
    
    let headerUserInfoStackView = {
        let st = UIStackView();
        st.axis = .vertical;
        st.alignment = .top;
        st.spacing = 5;
        
        return st;
    }();
    
    private let userNameStackView:UIStackView = {
        let st = UIStackView();
        st.axis = .horizontal;
        st.alignment = .center;
        st.spacing = 10;
        return st;
    }();
    
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 20)
        label.textColor = .white;
        label.text = "유저이름"
        return label
    }()
    
    
    private let crownIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "crown.fill"))
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let pointButtonContainerView: UIView = {
        let view = UIView()
        
        return view
    }()
    
    
    private let pointButton:UIButton = {
        let button = UIButton();
        button.backgroundColor = .tabbarGray;
        button.layer.cornerRadius = 8;
        button.layer.masksToBounds = true;
        
        let image = UIImage(systemName: "p.circle.fill")
        button.setImage(image, for: .normal)
        button.tintColor = .white
          
 
        button.setTitle("3100", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        
         
        button.contentHorizontalAlignment = .center
        button.imageView?.contentMode = .scaleAspectFit
        
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 5)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: -5)
        
        return button;
    }();
    
    private let manageAccountButton: UIButton = {
        let button = UIButton()
        button.setTitle("계정 관리", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12)
        return button
    }()
    
    let imageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
        imageView.image = UIImage(systemName: "person.circle")
        imageView.tintColor = .white
        return imageView
    }();
    
    
    let firstSectionStackView = {
        let st = UIStackView();
        st.axis = .vertical;
        st.alignment = .leading;
        st.spacing = 20;
        return st;
    }();
    
    let firstSectionHeaderStackView = {
        let st = UIStackView();
        st.axis = .horizontal;
        st.alignment = .fill;
        st.distribution = .equalSpacing
        return st;
    }();
    
    let firstSectionHeaderLabel = {
        let label = UILabel();
        label.text = "활동기록"
        label.font = .boldSystemFont(ofSize: 22)
        label.textColor = .white;
        return label;
    }();
    
    let firstSectionHeaderButton = {
        let button = UIButton();
        button.layer.borderColor = UIColor.white.cgColor;
        button.layer.borderWidth = 1;
        button.layer.cornerRadius = 10;
        button.layer.masksToBounds = true;
        button.setTitle("모두 보기", for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12);
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)

        return button;
    }()
    
    
    private lazy var collectionView = {
        
        let layout = UICollectionViewFlowLayout();
        layout.scrollDirection = .horizontal;
        layout.minimumLineSpacing = 10;
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16) // ✅ 좌우 패딩 설정

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self

        collectionView.register(ActivitySmallCell.self, forCellWithReuseIdentifier: ActivitySmallCell.identifier)
        return collectionView;
    }()
    
    
    
    let secondSectionStackView = {
        let st = UIStackView();
        st.axis = .vertical;
        st.alignment = .leading;
        st.spacing = 20;
        return st;
    }();
    
    let secondSectionHeaderStackView = {
        let st = UIStackView();
        st.axis = .horizontal;
        st.alignment = .fill;
        st.distribution = .equalSpacing
        return st;
    }();
    
    let secondSectionHeaderLabel = {
        let label = UILabel();
        label.text = "알림"
        label.font = .boldSystemFont(ofSize: 22)
        label.textColor = .white;
        return label;
    }();
    
    let secondSectionHeaderButton = {
        let button = UIButton();
        button.layer.borderColor = UIColor.white.cgColor;
        button.layer.borderWidth = 1;
        button.layer.cornerRadius = 10;
        button.layer.masksToBounds = true;
        button.setTitle("모두 보기", for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12);
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)

        return button;
    }()
    
    
    private lazy var tableView = {
        let tv = UITableView();
        tv.dataSource = self
        tv.delegate = self
        tv.register(AlertCell.self, forCellReuseIdentifier: AlertCell.identifier)
        tv.backgroundColor = .clear
        return tv;
    }()
    
    
    
    private let activities = ["달리치안스", "달리치안스", "달리치안스", "달리치안스", "달리치안스"]
    private let alerts = ["one", "two",]

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI();
        setupConstraint();
        setupStyle();
        // Do any additional setup after loading the view.
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        DispatchQueue.main.async {
            self.setupHeaderBottomCornerRadius()
        }
    }
    
    private func setupHeaderBottomCornerRadius() {
        let path = UIBezierPath(
            roundedRect: headerWrapperView.bounds,
            byRoundingCorners: [.bottomLeft, .bottomRight], // 하단 모서리만 적용
            cornerRadii: CGSize(width: 15, height: 15) // 원하는 반경 설정
        )

        let mask = CAShapeLayer()
        mask.path = path.cgPath
        headerWrapperView.layer.mask = mask
    }

    
    private func setupUI(){
        view.addSubview(safeWrapperView)
        
        safeWrapperView.addSubview(headerWrapperView)
        headerWrapperView.addSubview(headerStackView)
    
        
        headerStackView.addArrangedSubview(imageView)
        headerStackView.addArrangedSubview(headerUserInfoStackView)
        headerStackView.addArrangedSubview(pointButtonContainerView);
        
        headerUserInfoStackView.addArrangedSubview(userNameStackView);
        userNameStackView.addArrangedSubview(userNameLabel);
        userNameStackView.addArrangedSubview(crownIcon);
        
        pointButtonContainerView.addSubview(pointButton)
        
        headerUserInfoStackView.addArrangedSubview(manageAccountButton)
        
        
        safeWrapperView.addSubview(firstSectionStackView);
        firstSectionStackView.addArrangedSubview(firstSectionHeaderStackView);
        firstSectionStackView.addArrangedSubview(collectionView);
    
        firstSectionHeaderStackView.addArrangedSubview(firstSectionHeaderLabel);
        firstSectionHeaderStackView.addArrangedSubview(firstSectionHeaderButton);
        
        safeWrapperView.addSubview(secondSectionStackView);
        secondSectionStackView.addArrangedSubview(secondSectionHeaderStackView);

        
        secondSectionHeaderStackView.addArrangedSubview(secondSectionHeaderLabel);
        secondSectionHeaderStackView.addArrangedSubview(secondSectionHeaderButton);

        
        safeWrapperView.addSubview(tableView);
        

    }
    
    private func setupConstraint(){
        safeWrapperView.snp.makeConstraints{make in
            make.top.trailing.leading.bottom.equalTo(view.safeAreaLayoutGuide);
        }
        
        headerWrapperView.snp.makeConstraints{make in
            make.top.trailing.leading.equalTo(safeWrapperView);
            make.height.equalTo(100)
        }

        headerStackView.snp.makeConstraints{make in
            make.top.leading.equalTo(headerWrapperView).offset(10);
            make.bottom.trailing.equalTo(headerWrapperView).inset(10);
        }
        
        imageView.snp.makeConstraints{make in
            make.width.equalTo(65);
            make.height.equalTo(65);
        }
        
        
        crownIcon.snp.makeConstraints{make in
            make.width.equalTo(20);
            make.height.equalTo(20);
        }
        
        pointButtonContainerView.snp.makeConstraints { make in
            make.top.equalTo(headerWrapperView.snp.top)
            make.bottom.equalTo(headerWrapperView.snp.bottom)
        
        }

        pointButton.snp.makeConstraints { make in
            make.trailing.equalTo(pointButtonContainerView.snp.trailing)
            make.top.equalTo(pointButtonContainerView.snp.top).offset(15)
            make.width.equalTo(90);
            make.height.equalTo(40)
        }
        
        firstSectionStackView.snp.makeConstraints{ make in
            make.top.equalTo(headerWrapperView.snp.bottom).offset(35);
            make.leading.equalTo(view.safeAreaLayoutGuide);
            make.trailing.equalTo(view.safeAreaLayoutGuide);
        }
        
        
        firstSectionHeaderStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20)
        }
        
        
        collectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(50)
            make.height.equalTo(110) // 카드 높이 설정
        }
        
        
        secondSectionStackView.snp.makeConstraints{ make in
            make.top.equalTo(firstSectionStackView.snp.bottom).offset(35);
            make.leading.equalTo(view.safeAreaLayoutGuide);
            make.trailing.equalTo(view.safeAreaLayoutGuide);
        }
        
        
        secondSectionHeaderStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20)
        }
        
        
        tableView.snp.makeConstraints{ make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(secondSectionStackView.snp.bottom).offset(20)
        }
        

        
    }
    
    private func setupStyle(){
        view.backgroundColor = UIColor.lightGray
        
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

extension MyInfoViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return activities.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ActivitySmallCell.identifier, for: indexPath) as! ActivitySmallCell;
        cell.configure(text: activities[indexPath.item]) // 셀 데이터 적용
        return cell;
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
          return CGSize(width: 200, height: 110) // 카드 크기 설정
      }
}



extension MyInfoViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        alerts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AlertCell.identifier , for: indexPath) as? AlertCell else {
            return  UITableViewCell()
        }
        
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        return cell;
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    
}



