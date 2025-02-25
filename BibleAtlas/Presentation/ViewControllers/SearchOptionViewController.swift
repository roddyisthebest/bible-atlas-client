//
//  SearchViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/4/25.
//

import UIKit

class SearchOptionViewController: UIViewController {

    
    let bibleImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named:"bibleImage"));
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        return imageView;
    }()
    
    lazy var buttonStackView:UIStackView = {
        let st = UIStackView();
        st.axis = .vertical;
        st.alignment = .fill;
        st.distribution = .fillEqually;
        st.spacing = 10.0;
        
        st.addArrangedSubview(imageSearchButton)
        st.addArrangedSubview(keywordSearchButton)
        st.addArrangedSubview(bibleSearchButton)
        return st;
    }();
    
    let imageSearchButton:UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.thirdGray
        button.setTitleColor(.white, for: .normal)
        button.setTitle("이미지로 검색하기", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let icon = UIImage(systemName: "photo.artframe", withConfiguration: iconConfig)?
            .withTintColor(.primaryViolet, renderingMode: .alwaysOriginal)
        
        button.setImage(icon, for: .normal)
        button.contentHorizontalAlignment = .left
            
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0);
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 0);
        

        button.layer.cornerRadius = 8;
        return button
    }()
    
    
    let keywordSearchButton:UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.thirdGray
        button.setTitleColor(.white, for: .normal)
        button.setTitle("키워드로 검색하기", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let icon = UIImage(systemName: "captions.bubble.fill", withConfiguration: iconConfig)?
            .withTintColor(.primaryViolet, renderingMode: .alwaysOriginal)
        
        button.setImage(icon, for: .normal)
        button.contentHorizontalAlignment = .left
            
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0);
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 0);
        
        button.addTarget(self, action: #selector(keywordSearchButtonTapped), for:.touchUpInside)

        button.layer.cornerRadius = 8;
        return button
    }()
    
    
    let bibleSearchButton:UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.thirdGray
        button.setTitleColor(.white, for: .normal)
        button.setTitle("성경으로 검색하기", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let icon = UIImage(systemName: "book.fill", withConfiguration: iconConfig)?
            .withTintColor(.primaryViolet, renderingMode: .alwaysOriginal)
        
        button.setImage(icon, for: .normal)
        button.contentHorizontalAlignment = .left
            
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0);
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 0);
        

        button.layer.cornerRadius = 8;
        return button
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupStyle();
        setupUI();
        setupConstraint();
        
    }
    
    private func setupUI(){
        view.addSubview(bibleImageView);
        view.addSubview(buttonStackView);
    }
    
    private func setupConstraint(){
        bibleImageView.snp.makeConstraints{make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(30);
            make.trailing.leading.equalToSuperview().offset(20);
            make.height.equalTo(200)
        }
        
        buttonStackView.snp.makeConstraints{make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(30)
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);

        }
        
        imageSearchButton.snp.makeConstraints{make in make.height.equalTo(65)}
        keywordSearchButton.snp.makeConstraints{make in make.height.equalTo(65)}
        bibleSearchButton.snp.makeConstraints{make in make.height.equalTo(65)}
    }
    
    private func setupStyle(){
        view.backgroundColor = .tabbarGray

    }
    
    
    @objc private func keywordSearchButtonTapped(){
        let searchVC = SearchViewController();
        searchVC.modalPresentationStyle = .fullScreen
        present(searchVC,animated: false);
    }


}
