//
//  AppDelegate.swift
//  PhotoFileManager
//
//  Created by 2979820979 on 11/23/25.
//

import UIKit
import Photos

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 请求相册权限
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                print("相册权限已授权")
            } else {
                print("相册权限被拒绝")
            }
        }
        return true
    }

    func application(_ configuration: UISceneConfiguration, connecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
