//
//  MainTabBarController.swift
//  PhotoFileManager
//
//  Created by 2979820979 on 11/26/25.
//

import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
    }
    
    private func setupViewControllers() {
        // 照片浏览页面
        let browseVC = PhotoBrowseViewController()
        browseVC.tabBarItem = UITabBarItem(
            title: "浏览照片",
            image: UIImage(systemName: "photo.on.rectangle"),
            selectedImage: UIImage(systemName: "photo.on.rectangle.fill")
        )
        let browseNav = UINavigationController(rootViewController: browseVC)
        
        // 选项页面
        let optionsVC = OptionsViewController()
        optionsVC.tabBarItem = UITabBarItem(
            title: "选项",
            image: UIImage(systemName: "slider.horizontal.3"),
            selectedImage: UIImage(systemName: "slider.horizontal.3")
        )
        let optionsNav = UINavigationController(rootViewController: optionsVC)
        
        self.viewControllers = [browseNav, optionsNav]
    }
}
