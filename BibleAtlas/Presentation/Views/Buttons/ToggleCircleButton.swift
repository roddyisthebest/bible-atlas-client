//
//  ToggleCircleButton.swift
//  BibleAtlas
//
//  Created by 배성연 on 6/3/25.
//

import UIKit

final class ToggleCircleButton: UIButton {

    private let loadingView = LoadingView(style: .medium)
    private var activeImage:UIImage?
    private var inActiveImage:UIImage?
    
    private var isActive:Bool?{
        didSet{
            if(isActive ?? false){
                self.setImage(activeImage, for: .normal)
            }
            else{
                self.setImage(inActiveImage, for: .normal)
            }
        }
    }
    
    init(activeIconSystemName: String, inActiveIconSystemName: String) {
        super.init(frame: .zero)
        self.backgroundColor = .circleButtonBkg
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        
        let activeIcon = UIImage(systemName: activeIconSystemName, withConfiguration: config)
        
        let inActiveIcon = UIImage(systemName: inActiveIconSystemName, withConfiguration: config)
        
        self.activeImage = activeIcon
        self.inActiveImage = inActiveIcon
        
        self.setImage(inActiveImage, for: .normal)

        self.backgroundColor = .circleButtonBkg
        
        self.snp.makeConstraints { make in
            make.width.height.equalTo(30)
        }
        
        self.layer.cornerRadius = 15
        self.layer.masksToBounds = true
        
        self.tintColor = .circleIcon
        setupLoadingView()

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLoadingView() {
        addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        loadingView.isHidden = true
    }
    
    public func setActive(isActive:Bool){
        self.isActive = isActive;
    }
    
    public func startLoading() {
        self.isEnabled = false
        self.setImage(nil, for: .normal)
        loadingView.start()
    }

    public func stopLoading() {
        self.isEnabled = true
        loadingView.stop()
        setActive(isActive: self.isActive ?? false)
    }

}


#if DEBUG

extension ToggleCircleButton {
    // 읽기 전용 상태/뷰 확인용
  
    var _test_loadingView:UIActivityIndicatorView {
        loadingView
    }
}
#endif
