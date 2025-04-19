//
//  MainViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/19/25.
//

import UIKit
import MapKit

final class MainViewController: UIViewController,BottomSheetPresentable {

    private var navigator: BottomSheetNavigator;

    private lazy var mapView = {
        let mv = MKMapView();
        view.addSubview(mv)
        return mv;
    }()

    private func setupUI(){
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview();
        }
    }
    
            
    init(navigator:BottomSheetNavigator) {
        self.navigator = navigator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI();
    }
    
    func present(_ viewController: UIViewController, animated: Bool) {
        super.present(viewController, animated: animated)
     }

     func dismiss(animated: Bool) {
         super.dismiss(animated: animated)
     }
    

}
