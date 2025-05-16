//
//  MapViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/3/25.
//

import UIKit
import MapKit
class MapViewController: UIViewController {

    private lazy var mapView = {
        let mv = MKMapView();
        mv.layoutMargins = .zero

        view.addSubview(mv)
        return mv;
    }()
    
    private func setupUI(){
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview();
        }
                
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // Do any additional setup after loading the view.
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
