//
//  SceneDelegate.swift
//  PhotoFileManager
//
//  Created by 2979820979 on 11/23/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        let mainViewController = MainTabBarController()
        window?.rootViewController = mainViewController
        window?.makeKeyAndVisible()
    }
}
