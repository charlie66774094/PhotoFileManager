//
//  GroupPhotoCell.swift
//  PhotoFileManager
//
//  Created by 2979820979 on 11/26/25.
//

import UIKit
import Photos

protocol GroupPhotoCellDelegate: AnyObject {
    func didTapKeep(on asset: PHAsset)
    func didTapDelete(on asset: PHAsset)
}

class GroupPhotoCell: UICollectionViewCell {
    
    weak var delegate: GroupPhotoCellDelegate?
    private var asset: PHAsset?
    
    private let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray5
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let keepButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("保留", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.layer.cornerRadius = 6
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("删除", for: .normal)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.layer.cornerRadius = 6
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 12
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 4
        contentView.layer.shadowOpacity = 0.1
        
        contentView.addSubview(photoImageView)
        contentView.addSubview(dateLabel)
        contentView.addSubview(keepButton)
        contentView.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            photoImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            photoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            photoImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            photoImageView.heightAnchor.constraint(equalTo: photoImageView.widthAnchor),
            
            dateLabel.topAnchor.constraint(equalTo: photoImageView.bottomAnchor, constant: 8),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            
            keepButton.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
            keepButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            keepButton.widthAnchor.constraint(equalTo: deleteButton.widthAnchor),
            keepButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            keepButton.heightAnchor.constraint(equalToConstant: 30),
            
            deleteButton.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
            deleteButton.leadingAnchor.constraint(equalTo: keepButton.trailingAnchor, constant: 8),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            deleteButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            deleteButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        keepButton.addTarget(self, action: #selector(keepButtonTapped), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }
    
    func configure(with asset: PHAsset) {
        self.asset = asset
        
        if let date = asset.creationDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd HH:mm"
            dateLabel.text = formatter.string(from: date)
        }
        
        let targetSize = CGSize(width: 150, height: 150)
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: nil
        ) { [weak self] image, _ in
            self?.photoImageView.image = image
        }
    }
    
    @objc private func keepButtonTapped() {
        guard let asset = asset else { return }
        delegate?.didTapKeep(on: asset)
    }
    
    @objc private func deleteButtonTapped() {
        guard let asset = asset else { return }
        delegate?.didTapDelete(on: asset)
    }
}
