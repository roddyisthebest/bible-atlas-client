//
//  PlacesByTypeViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/11/25.
//

import UIKit
import RxSwift
import RxRelay

final class PlaceTypesBottomSheetViewController: UIViewController {

    private var placeTypesBottomSheetViewModel: PlaceTypesBottomSheetViewModelProtocol?
    
    private let placeTypeCellTapped$ = PublishRelay<Int>()
    
    private let dummyPlaces:[String] = ["water Of Body", "land", "land park", "ground" , "underground", "water Of Body", "land", "land park", "ground" , "underground", "water Of Body", "land", "land park", "ground" , "underground", "water Of Body", "land", "land park", "ground" , "underground"];
    
    private lazy var headerStackView = {
        let sv = UIStackView(arrangedSubviews: [headerLabel, closeButton]);
        sv.axis = .horizontal;
        sv.distribution = .fillProportionally;
        sv.alignment = .center;
        return sv;
    }()
    
    
    private let headerLabel = HeaderLabel(text: "Places By Type");
    private let closeButton = CircleButton(iconSystemName: "xmark");

    
    private lazy var collectionView:UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.delegate = self
        cv.dataSource = self
        cv.register(PlaceTypeCell.self,forCellWithReuseIdentifier: PlaceTypeCell.identifier);
        cv.backgroundColor = .mainItemBkg
        cv.layer.cornerRadius = 8;
        cv.layer.masksToBounds = true
        cv.isScrollEnabled = true
        return cv
    }()
    
    private func setupUI(){
        view.addSubview(headerStackView)
        view.addSubview(collectionView)
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
        
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(headerStackView.snp.bottom).offset(20);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);
            make.bottom.equalToSuperview().inset(20);
        }
        
    }
    
    private func bindViewModel(){
        
        let closeButtonTapped$ = closeButton.rx.tap.asObservable()
        
        placeTypesBottomSheetViewModel?.transform(input: PlaceTypesBottomSheetViewModel.Input(placeTypeCellTapped$: placeTypeCellTapped$.asObservable(),closeButtonTapped$: closeButtonTapped$))
    }
    
    
    init(vm:PlaceTypesBottomSheetViewModelProtocol){
        self.placeTypesBottomSheetViewModel = vm
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupStyle()
        setupConstraints()
        bindViewModel()
    }

}

extension PlaceTypesBottomSheetViewController: UICollectionViewDelegate, UICollectionViewDataSource{
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dummyPlaces.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlaceTypeCell.identifier, for: indexPath) as! PlaceTypeCell
            cell.configure(text: dummyPlaces[indexPath.item])

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedPlace = dummyPlaces[indexPath.item]
        placeTypeCellTapped$.accept(1)
    }
    
    
}

extension PlaceTypesBottomSheetViewController:UICollectionViewDelegateFlowLayout{
    
        func collectionView(_ collectionView: UICollectionView,
                           layout collectionViewLayout: UICollectionViewLayout,
                           sizeForItemAt indexPath: IndexPath) -> CGSize {

           let spacing: CGFloat = 10
           let totalSpacing = spacing * 2 + spacing * 2 // 좌우 inset + 두 번의 간격
           let itemWidth = (collectionView.bounds.width - totalSpacing) / 3

           return CGSize(width: itemWidth, height: itemWidth + 20) // height는 적절히 조절
       }

       func collectionView(_ collectionView: UICollectionView,
                           layout collectionViewLayout: UICollectionViewLayout,
                           minimumLineSpacingForSectionAt section: Int) -> CGFloat {
           return 0
       }

       func collectionView(_ collectionView: UICollectionView,
                           layout collectionViewLayout: UICollectionViewLayout,
                           minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
           return 10
       }
    
    
}
