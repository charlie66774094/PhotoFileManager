//
//  PhotoPreviewViewController.swift
//  PhotoFileManager
//
//  Created by 2979820979 on 11/26/25.
//

import UIKit
import Photos

class PhotoPreviewViewController: UIViewController {
    
    var asset: PHAsset?
    var isDeleted: Bool = false
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadPhoto()
    }
    
    private func setupUI() {
        title = "照片详情"
        view.backgroundColor = .systemBackground
        
        view.addSubview(imageView)
        view.addSubview(infoLabel)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            imageView.bottomAnchor.constraint(equalTo: infoLabel.topAnchor, constant: -20),
            
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            infoLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func loadPhoto() {
        guard let asset = asset else { return }
        
        let targetSize = CGSize(
            width: view.bounds.width * UIScreen.main.scale,
            height: view.bounds.height * UIScreen.main.scale
        )
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: nil
        ) { [weak self] image, _ in
            self?.imageView.image = image
        }
        
        // 显示照片信息
        var infoText = "照片ID: \(asset.localIdentifier)\n"
        
        if let date = asset.creationDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            infoText += "创建时间: \(formatter.string(from: date))\n"
        }
        
        infoText += "状态: \(isDeleted ? "已删除" : "已保留")"
        infoLabel.text = infoText
    }
}
