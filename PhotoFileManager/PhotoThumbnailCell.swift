//
//  PhotoThumbnailCell.swift
//  PhotoFileManager
//
//  Created by 2979820979 on 11/26/25.
//

import UIKit
import Photos

class PhotoThumbnailCell: UICollectionViewCell {
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let deletedOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let deletedLabel: UILabel = {
        let label = UILabel()
        label.text = "已删除"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(deletedOverlay)
        contentView.addSubview(deletedLabel)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            deletedOverlay.topAnchor.constraint(equalTo: contentView.topAnchor),
            deletedOverlay.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            deletedOverlay.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            deletedOverlay.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            deletedLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            deletedLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with asset: PHAsset, isDeleted: Bool) {
        deletedOverlay.isHidden = !isDeleted
        deletedLabel.isHidden = !isDeleted
        
        let targetSize = CGSize(width: 100, height: 100)
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: nil
        ) { [weak self] image, _ in
            self?.imageView.image = image
        }
    }
}
