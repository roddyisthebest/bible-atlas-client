//
//  PlacesByCharacterBottomSheetViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/15/25.
//

import UIKit
import RxSwift
import RxRelay

class PlacesByCharacterBottomSheetViewController: UIViewController {

    private var placesByCharacterBottomSheetViewModel:PlacesByCharacterBottomSheetViewModelProtocol?
    
    private let bottomReached$ = PublishRelay<Void>();
    private let placeCellTapped$ = PublishRelay<String>()

    private let disposeBag = DisposeBag();
    
    private let dummyPlaces:[String] = ["onasdasdasdasdasddfasdfdfasdfasdfasdfasdfasdfe", "sdfasdfadsfasdfasdffsdsadf","sda","dfsdfasdf","erer","dsff","dd","asdsd","sdsd","qweqwe","fdfdsd"];
    
    private lazy var headerStackView = {
        let v = UIView();
        
        v.snp.makeConstraints { make in
            make.width.height.equalTo(30);
        }
        
        let sv = UIStackView(arrangedSubviews: [v, headerLabel, closeButton]);
        sv.axis = .horizontal;
        sv.distribution = .equalSpacing;
        sv.alignment = .center;
        
        return sv;
    }()
    
    
    private let headerLabel = {
        
        let label = HeaderLabel(text:"Land")
        label.font = .boldSystemFont(ofSize: 20)
        return label;
    }()
    
    private let closeButton = CircleButton(iconSystemName: "xmark");

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
        view.addSubview(tableView)
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
        let closeButtonTapped$ = closeButton.rx.tap.asObservable()

        
        
        let output = placesByCharacterBottomSheetViewModel?.transform(input: PlacesByCharacterBottomSheetViewModel.Input(placeCellTapped$: placeCellTapped$.asObservable(), closeButtonTapped$: closeButtonTapped$,bottomReached$: bottomReached$.asObservable()))
        
        
        output?.character$.observe(on:MainScheduler.instance).bind{
            [weak self] character in
            print("hoo ha!")
            self?.headerLabel.text = "Sorted By \(character)"
        }.disposed(by: disposeBag)
        
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupStyle()
        setupConstraints()
        bindViewModel();
    }
    
    init(vm:PlacesByCharacterBottomSheetViewModelProtocol){
        self.placesByCharacterBottomSheetViewModel = vm
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}



extension PlacesByCharacterBottomSheetViewController:UITableViewDelegate, UITableViewDataSource {
    
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
        placeCellTapped$.accept(dummyPlaces[indexPath.row]);
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dummyPlaces.count;
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80;
    }
}
