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
        setStyle()
    }

    private func setupTabs() {
        let homeVC = HomeViewController()
        let searchOptionVC = SearchOptionViewController()
        let myInfoVC = MyInfoViewController()

        
        
        
        // 각 VC를 UINavigationController로 감싸기
        let homeNav = UINavigationController(rootViewController: homeVC)
        let searchNav = UINavigationController(rootViewController: searchOptionVC)
        let myInfoNav = UINavigationController(rootViewController: myInfoVC)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .thirdGray
        appearance.titleTextAttributes = [ .foregroundColor: UIColor.white]
        
        
        
        myInfoNav.navigationBar.standardAppearance = appearance
        myInfoNav.navigationBar.scrollEdgeAppearance = appearance


        
        homeNav.tabBarItem = UITabBarItem(title: "홈", image: UIImage(systemName: "house.fill"), tag: 0)
        searchNav.tabBarItem = UITabBarItem(title: "검색", image: UIImage(systemName: "magnifyingglass"), tag: 1)
        myInfoNav.tabBarItem = UITabBarItem(title: "프로필", image: UIImage(systemName: "person.fill"), tag: 2)
        self.viewControllers = [homeNav, searchNav, myInfoNav]
    }
    
    
    private func setStyle() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.primaryInput
        
        // ✅ 선택된 아이템 및 비선택 아이템 색상 설정
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]

        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.secondaryGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.secondaryGray]

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance

        tabBar.tintColor = UIColor.white
        tabBar.unselectedItemTintColor = UIColor.secondaryGray
        tabBar.isTranslucent = false
    }

}
