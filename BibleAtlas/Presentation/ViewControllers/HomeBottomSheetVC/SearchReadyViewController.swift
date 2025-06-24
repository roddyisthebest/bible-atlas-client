//
//  SearchReadyViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 6/21/25.
//

import UIKit

final class SearchReadyViewController: UIViewController {

    private let searchReadyViewModel: SearchReadyViewModelProtocol

    init(searchReadyViewModel: SearchReadyViewModelProtocol) {
           self.searchReadyViewModel = searchReadyViewModel
           super.init(nibName: nil, bundle: nil)
       }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints();

    }

    private func setupUI() {
        view.backgroundColor = .yellow
    }
    
    private func setupConstraints(){
        
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
