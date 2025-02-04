//
//  MainTabBarControllerViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/4/25.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
    }

    private func setupTabs() {
        let homeVC = HomeViewController()
        homeVC.tabBarItem = UITabBarItem(title: "홈", image: UIImage(systemName: "house.fill"), tag: 0)

        let searchVC = SearchViewController()
        searchVC.tabBarItem = UITabBarItem(title: "검색", image: UIImage(systemName: "magnifyingglass"), tag: 1)

        let myInfoVC = MyInfoViewController()
        myInfoVC.tabBarItem = UITabBarItem(title: "프로필", image: UIImage(systemName: "person.fill"), tag: 2)

        self.viewControllers = [homeVC, searchVC, myInfoVC]
    }
}
