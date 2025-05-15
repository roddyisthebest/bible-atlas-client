//
//  MyCollectionBottomSheetViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/26/25.
//

import UIKit
import RxSwift
import RxRelay
import PanModal
class MyCollectionBottomSheetViewController: UIViewController {
    

    
    private var myCollectionBottomSheetViewModel:MyCollectionBottomSheetViewModelProtocol?;
    
    private let disposeBag = DisposeBag();

    private let bottomReached$ = PublishRelay<Void>();
    private let placeTabelCellSelected$ = PublishRelay<String>();
    
    private let dummyPlaces:[String] = ["onasdasdasdasdasddfasdfdfasdfasdfasdfasdfasdfe", "sdfasdfadsfasdfasdffsdsadf"];
    
    
    
    private lazy var headerStackView = {
        let sv = UIStackView(arrangedSubviews: [headerLabel, closeButton]);
        sv.axis = .horizontal;
        sv.distribution = .fillProportionally;
        sv.alignment = .center
        
        return sv;
    }()
    
    
    private let headerLabel = HeaderLabel(text: "Favorites");
    
    private let closeButton = CircleButton(iconSystemName: "xmark")
    
    private lazy var tableView = {
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
    
    private func setupUI(){
        view.addSubview(headerStackView);
        view.addSubview(tableView);
    }
    
    private func setupStyle(){
        view.backgroundColor = .mainBkg;
    }
    
    private func setupConstraints(){
        headerStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);

        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerStackView.snp.bottom).offset(20);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);
            make.bottom.equalToSuperview().offset(-20);
            
        }
        
    }
    
    private func bindViewModel(){
        let closeButtonTapped$ = closeButton.rx.tap.asObservable();
        
        
        let output = myCollectionBottomSheetViewModel?.transform(input: MyCollectionBottomSheetViewModel.Input(closeButtonTapped$: closeButtonTapped$, placeTabelCellSelected$: placeTabelCellSelected$.asObservable(), bottomReached$: bottomReached$.asObservable()))
        
        output?.placesResponse$.observe(on: MainScheduler.instance).bind{
            [weak self] response in
            print(response,"response")
        }.disposed(by: disposeBag)
        
        output?.error$.observe(on: MainScheduler.instance).bind{
            [weak self] errorMsg in
            let alert = UIAlertController(title: "에러", message: errorMsg, preferredStyle: .alert);
            alert.addAction(.init(title:"확인", style:.default));
            self?.present(alert,animated: true);

        }.disposed(by: disposeBag)
        
        output?.type$.observe(on: MainScheduler.instance).bind{
            [weak self] type in           
                switch(type){
                case .favorite:
                    self?.headerLabel.text = "Favorite"
                case .memo:
                    self?.headerLabel.text = "Memo"
                case .save:
                    self?.headerLabel.text = "Save"
                }
            
          
        }.disposed(by: disposeBag)
        
    }
    

    
    
    init(myCollectionBottomSheetViewModel:MyCollectionBottomSheetViewModelProtocol) {
        self.myCollectionBottomSheetViewModel = myCollectionBottomSheetViewModel
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

}

extension MyCollectionBottomSheetViewController:UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PlaceTableViewCell.identifier, for: indexPath) as? PlaceTableViewCell else {
            return UITableViewCell()
        }

        cell.setText(text: dummyPlaces[indexPath.row])

        if indexPath.row == dummyPlaces.count - 1 {
               cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.width, bottom: 0, right: 0)
           } else {
               cell.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        }
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        placeTabelCellSelected$.accept(dummyPlaces[indexPath.row])
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dummyPlaces.count;
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80;
    }
}
