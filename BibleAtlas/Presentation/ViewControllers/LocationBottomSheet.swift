//
//  LocationBottomSheet.swift
//  BibleAtlas
//
//  Created by 배성연 on 3/8/25.
//

import UIKit

final class LocationBottomSheet: UIViewController {
    
    

    
    
    
    private lazy var container = {
        let v = UIView();
        v.backgroundColor = .thirdGray;
        view.addSubview(v)
        v.addSubview(titleStackView)
        v.addSubview(buttonsContainer)
        return v;
    }();
    
    
    private lazy var titleStackView = {
        let sv = UIStackView(arrangedSubviews: [titleTextContainerStackView,titleButtonsContainerStackView]);
        sv.axis = .horizontal;
        sv.distribution = .equalSpacing;
        sv.alignment = .fill;
        sv.spacing = 8;
        return sv;
    }();
    
    
    private lazy var titleTextContainerStackView = {
        let sv = UIStackView(arrangedSubviews: [globalImage, titleTextLabel]);
        sv.axis = .horizontal;
        sv.alignment = .center;
        sv.distribution = .fill;
        sv.spacing = 10;
        return sv;
    }();
    
    
    private lazy var globalImage = {
        let image = UIImage(systemName: "globe.americas.fill");
        let iv = UIImageView(image:image);
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .primaryViolet;
        
        
        return iv;
    }()
    
    private lazy var titleTextLabel = {
        let label = UILabel();
        label.font = UIFont.systemFont(ofSize: 20, weight: .heavy);
        label.textColor = .white;
        label.lineBreakMode = .byTruncatingTail;
        label.text = "코리치안스"
        return label;
    }();
    
    
    private lazy var titleButtonsContainerStackView = {
        let sv = UIStackView(arrangedSubviews: [shareButton, deleteButton]);
        sv.axis = .horizontal;
        sv.alignment = .center;
        sv.distribution = .fill;
        sv.spacing = 8;
        return sv;
    }();
    
    private let shareButton  = {
        var config = UIButton.Configuration.plain()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        config.preferredSymbolConfigurationForImage = imageConfig
        
        let button = UIButton(configuration: config)
        
        button.setImage(UIImage(systemName: "square.and.arrow.up.fill"), for: .normal)
        button.tintColor = .white;
        button.backgroundColor = .tabbarGray;
        button.layer.cornerRadius = 10;
        return button;
    }();
    
    private let deleteButton = {
        var config = UIButton.Configuration.plain()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        config.preferredSymbolConfigurationForImage = imageConfig
        
        let button = UIButton(configuration: config)
        
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .white;
        button.backgroundColor = .tabbarGray;
        button.layer.cornerRadius = 10;
        button.addTarget(self, action: #selector(closeBottomSheet), for: .touchUpInside)
        return button;
    }();
    
    
    
    private lazy var buttonsContainer = {
        let v = UIView();
        v.addSubview(detailButton)
        return v;
    }();
    
    
    private lazy var detailButton = {
        let button = UIButton()
        button.backgroundColor = .primaryViolet;
        button.layer.cornerRadius = 25
        button.addSubview(detailIcon)
        button.addSubview(detailButtonLabel)
        return button;
    }();
    
    
    private let detailIcon = {
        let image = UIImage(systemName: "eye.fill");
        let iv = UIImageView(image:image);
        iv.contentMode = .scaleAspectFit;
        iv.tintColor = .white;
        return iv;
    }();
    
    private let detailButtonLabel = {
        let label = UILabel();
        label.text = "자세히 보기"
        label.textColor = .white;
        label.font = .systemFont(ofSize: 20, weight: .heavy);
        return label;
    }();
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupConstraints();
        setupStyle()
    }
    
    init(locationTitle:String?){

        super.init(nibName: nil, bundle: nil)
        self.titleTextLabel.text = locationTitle

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func setupStyle(){
        view.backgroundColor = .clear

    }
    
    
    private func setupConstraints(){
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview();
        }
        
        
        titleStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
            
        }
        
        
        buttonsContainer.snp.makeConstraints { make in
            make.top.equalTo(titleStackView.snp.bottom)
            make.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
        }
        
        
  
        detailButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview();
            make.trailing.leading.equalToSuperview();
            make.height.equalTo(60)
        }
        
        detailIcon.snp.makeConstraints { make in
            make.width.height.equalTo(30);
            make.centerY.equalToSuperview();
            make.trailing.equalToSuperview().inset(20);

        }
        
        detailButtonLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview();
            make.leading.equalToSuperview().offset(20);
        }
        
        globalImage.snp.makeConstraints { make in
            make.width.height.equalTo(30)
        }
        
        
    }
    
    
    
    @objc private func closeBottomSheet(){
        dismiss(animated: true)
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
