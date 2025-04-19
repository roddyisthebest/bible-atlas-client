//
//  MainViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/19/25.
//

import UIKit
import MapKit

class MainViewController: UIViewController {

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
    
            
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI();
    }
    

    

}
