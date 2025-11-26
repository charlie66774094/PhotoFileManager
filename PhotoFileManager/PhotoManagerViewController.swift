//
//  PhotoManagerViewController.swift
//  PhotoFileManager
//
//  Created by 2979820979 on 11/23/25.
//

import UIKit
import Photos
import CryptoKit

class PhotoManagerViewController: UIViewController {
    
    // MARK: - Properties
    private var allPhotos: [PHAsset] = []
    private var randomPhotos: [PHAsset] = []
    private var keptPhotos: Set<String> = [] // 保存已保留照片的localIdentifier
    private var deletedPhotos: Set<String> = [] // 保存已删除照片的localIdentifier
    private var duplicateGroups: [[PHAsset]] = []
    
    // MARK: - UI Components
    private let statsView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let keptLabel: UILabel = {
        let label = UILabel()
        label.text = "已保留: 0"
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemGreen
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let deletedLabel: UILabel = {
        let label = UILabel()
        label.text = "已删除: 0"
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemRed
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let remainingLabel: UILabel = {
        let label = UILabel()
        label.text = "剩余: 0"
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: "PhotoCell")
        return collectionView
    }()
    
    private let mergeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("检测并合并重复照片", for: .normal)
        button.backgroundColor = .systemOrange
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let refreshButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("刷新随机照片", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserData()
        loadPhotos()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "照片清理助手"
        view.backgroundColor = .systemBackground
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        setupStatsView()
        view.addSubview(collectionView)
        view.addSubview(mergeButton)
        view.addSubview(refreshButton)
        
        NSLayoutConstraint.activate([
            statsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            statsView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statsView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            statsView.heightAnchor.constraint(equalToConstant: 60),
            
            collectionView.topAnchor.constraint(equalTo: statsView.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: mergeButton.topAnchor, constant: -8),
            
            mergeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            mergeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            mergeButton.bottomAnchor.constraint(equalTo: refreshButton.topAnchor, constant: -8),
            mergeButton.heightAnchor.constraint(equalToConstant: 50),
            
            refreshButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            refreshButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            refreshButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            refreshButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        mergeButton.addTarget(self, action: #selector(mergeDuplicates), for: .touchUpInside)
        refreshButton.addTarget(self, action: #selector(refreshRandomPhotos), for: .touchUpInside)
    }
    
    private func setupStatsView() {
        view.addSubview(statsView)
        
        let stackView = UIStackView(arrangedSubviews: [keptLabel, deletedLabel, remainingLabel])
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        statsView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: statsView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: statsView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: statsView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: statsView.bottomAnchor, constant: -8)
        ])
    }
    
    // MARK: - Data Management
    private func loadUserData() {
        // 从UserDefaults加载已保留和已删除的照片记录
        if let kept = UserDefaults.standard.stringArray(forKey: "keptPhotos") {
            keptPhotos = Set(kept)
        }
        if let deleted = UserDefaults.standard.stringArray(forKey: "deletedPhotos") {
            deletedPhotos = Set(deleted)
        }
        updateStats()
    }
    
    private func saveUserData() {
        UserDefaults.standard.set(Array(keptPhotos), forKey: "keptPhotos")
        UserDefaults.standard.set(Array(deletedPhotos), forKey: "deletedPhotos")
        updateStats()
    }
    
    private func updateStats() {
        keptLabel.text = "已保留: \(keptPhotos.count)"
        deletedLabel.text = "已删除: \(deletedPhotos.count)"
        remainingLabel.text = "剩余: \(allPhotos.count - keptPhotos.count - deletedPhotos.count)"
    }
    
    private func loadPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        allPhotos.removeAll()
        
        fetchResult.enumerateObjects { asset, _, _ in
            // 过滤掉已保留和已删除的照片
            if !self.keptPhotos.contains(asset.localIdentifier) &&
               !self.deletedPhotos.contains(asset.localIdentifier) {
                self.allPhotos.append(asset)
            }
        }
        
        refreshRandomPhotos()
    }
    
    @objc private func refreshRandomPhotos() {
        // 从剩余照片中随机选择最多9张
        let availablePhotos = allPhotos.filter {
            !keptPhotos.contains($0.localIdentifier) &&
            !deletedPhotos.contains($0.localIdentifier)
        }
        
        randomPhotos = Array(availablePhotos.shuffled().prefix(9))
        duplicateGroups.removeAll()
        collectionView.reloadData()
    }
    
    // MARK: - Photo Actions
    private func keepPhoto(_ asset: PHAsset) {
        keptPhotos.insert(asset.localIdentifier)
        saveUserData()
        refreshRandomPhotos()
    }
    
    private func deletePhoto(_ asset: PHAsset) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets([asset] as NSArray)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.deletedPhotos.insert(asset.localIdentifier)
                    self.saveUserData()
                    self.refreshRandomPhotos()
                } else {
                    self.showAlert(title: "删除失败", message: error?.localizedDescription ?? "未知错误")
                }
            }
        }
    }
    
    // MARK: - Duplicate Detection
    @objc private func mergeDuplicates() {
        showLoadingAlert(title: "正在检测重复照片...")
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.findDuplicatePhotos { duplicates in
                DispatchQueue.main.async {
                    self.dismiss(animated: true) {
                        if duplicates.isEmpty {
                            self.showAlert(title: "提示", message: "没有找到重复的照片")
                        } else {
                            self.showMergeConfirmation(duplicates: duplicates)
                        }
                    }
                }
            }
        }
    }
    
    private func findDuplicatePhotos(completion: @escaping ([[PHAsset]]) -> Void) {
        var photoHashes: [String: [PHAsset]] = [:]
        let group = DispatchGroup()
        
        for asset in allPhotos {
            guard !keptPhotos.contains(asset.localIdentifier) else { continue }
            
            group.enter()
            getImageData(for: asset) { imageData in
                if let data = imageData {
                    let hash = self.sha256(data: data)
                    if photoHashes[hash] == nil {
                        photoHashes[hash] = []
                    }
                    photoHashes[hash]?.append(asset)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            let duplicates = photoHashes.values.filter { $0.count > 1 }
            completion(duplicates)
        }
    }
    
    private func getImageData(for asset: PHAsset, completion: @escaping (Data?) -> Void) {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        
        PHImageManager.default().requestImageDataAndOrientation(
            for: asset,
            options: options
        ) { data, _, _, _ in
            completion(data)
        }
    }
    
    private func sha256(data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Alerts
    private func showLoadingAlert(title: String) {
        let alert = UIAlertController(title: title, message: "\n\n", preferredStyle: .alert)
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()
        
        alert.view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: alert.view.centerYAnchor)
        ])
        
        present(alert, animated: true)
    }
    
    private func showMergeConfirmation(duplicates: [[PHAsset]]) {
        let totalDuplicates = duplicates.reduce(0) { $0 + $1.count - 1 }
        let alert = UIAlertController(
            title: "发现重复照片",
            message: "找到 \(duplicates.count) 组重复照片，共 \(totalDuplicates) 张可删除。是否合并？",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "合并", style: .destructive) { _ in
            self.mergeDuplicatePhotos(duplicates)
        })
        
        present(alert, animated: true)
    }
    
    private func mergeDuplicatePhotos(_ duplicates: [[PHAsset]]) {
        var deletedCount = 0
        
        PHPhotoLibrary.shared().performChanges({
            for group in duplicates {
                // 保留第一张，删除其他的
                for asset in group.dropFirst() {
                    PHAssetChangeRequest.deleteAssets([asset] as NSArray)
                    deletedCount += 1
                    self.deletedPhotos.insert(asset.localIdentifier)
                }
            }
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.saveUserData()
                    self.showAlert(title: "合并完成", message: "成功删除 \(deletedCount) 张重复照片")
                    self.refreshRandomPhotos()
                } else {
                    self.showAlert(title: "合并失败", message: error?.localizedDescription ?? "未知错误")
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension PhotoManagerViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return randomPhotos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        let asset = randomPhotos[indexPath.item]
        cell.configure(with: asset)
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 16
        let collectionViewSize = collectionView.frame.size.width - padding
        let width = collectionViewSize / 2
        return CGSize(width: width, height: width + 80)
    }
}

// MARK: - PhotoCellDelegate
extension PhotoManagerViewController: PhotoCellDelegate {
    
    func didTapKeep(on asset: PHAsset) {
        keepPhoto(asset)
    }
    
    func didTapDelete(on asset: PHAsset) {
        let alert = UIAlertController(
            title: "删除照片",
            message: "确定要删除这张照片吗？此操作不可撤销。",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { _ in
            self.deletePhoto(asset)
        })
        
        present(alert, animated: true)
    }
}
