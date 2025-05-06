//
//  PlaceDetailViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/3/25.
//

import UIKit

class PlaceDetailViewController: UIViewController {
    
    
    private lazy var bodyView = {
        let v = UIView();
        v.addSubview(headerStackView);
        v.addSubview(scrollView);
        return v;
    }()
    
    private lazy var scrollView = {
        let sv = UIScrollView();
        sv.addSubview(contentView)
        return sv;
    }()
    
    private lazy var contentView = {
        let v = UIView()
//        v.addSubview(headerStackView);
        return v
    }()
    
    private lazy var headerStackView = {
        let sv = UIStackView(arrangedSubviews: [titleLabel, buttonsStackView]);
        sv.axis = .horizontal;
        sv.distribution = .fill;
        sv.alignment = .leading;
        sv.spacing = 20;
        return sv;
    }()
    
    private let titleLabel = HeaderLabel(text:"믿을 수 없는 기적들");
    
    private lazy var buttonsStackView = {
        let sv = UIStackView(arrangedSubviews: [saveButton, shareButton, closeButton]);
        sv.axis = .horizontal;
        sv.distribution = .fill;
        sv.alignment = .fill
        sv.spacing = 8;
        return sv;
    }()
    
    private let saveButton = CircleButton(iconSystemName:"bookmark")
    
    private let shareButton = CircleButton(iconSystemName: "square.and.arrow.up")
    
    private let closeButton = CircleButton(iconSystemName: "xmark")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI();
        setupConstraints()
    }
    
    private func setupUI(){
        view.addSubview(bodyView)
    }
    
    private func setupConstraints(){
        bodyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        headerStackView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);
            make.height.equalTo(40);
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(headerStackView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
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
