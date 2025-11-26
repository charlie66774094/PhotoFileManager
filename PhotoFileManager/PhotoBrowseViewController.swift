//
//  PhotoBrowseViewController.swift
//  PhotoFileManager
//
//  Created by 2979820979 on 11/26/25.
//

import UIKit
import Photos
import CryptoKit

class PhotoBrowseViewController: UIViewController {
    
    // MARK: - Properties
    private var allPhotos: [PHAsset] = []
    private var currentGroup: [PHAsset] = []
    private var currentIndex: Int = 0
    private var keptPhotos: Set<String> = []
    private var deletedPhotos: Set<String> = []
    private let groupSize = 6 // 每组显示6张照片
    
    // MARK: - UI Components
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.register(GroupPhotoCell.self, forCellWithReuseIdentifier: "GroupPhotoCell")
        return collectionView
    }()
    
    private let groupInfoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let completeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("完成本组浏览", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let statsView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let keptLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemGreen
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let deletedLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemRed
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let remainingLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserData()
        loadPhotos()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateStats()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "照片分组浏览"
        view.backgroundColor = .systemBackground
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        setupStatsView()
        view.addSubview(groupInfoLabel)
        view.addSubview(collectionView)
        view.addSubview(completeButton)
        
        NSLayoutConstraint.activate([
            statsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            statsView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statsView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            statsView.heightAnchor.constraint(equalToConstant: 60),
            
            groupInfoLabel.topAnchor.constraint(equalTo: statsView.bottomAnchor, constant: 8),
            groupInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            groupInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            groupInfoLabel.heightAnchor.constraint(equalToConstant: 30),
            
            collectionView.topAnchor.constraint(equalTo: groupInfoLabel.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: completeButton.topAnchor, constant: -16),
            
            completeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            completeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            completeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            completeButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        completeButton.addTarget(self, action: #selector(completeCurrentGroup), for: .touchUpInside)
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
        remainingLabel.text = "剩余: \(allPhotos.count)"
    }
    
    private func loadPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        allPhotos.removeAll()
        
        fetchResult.enumerateObjects { asset, _, _ in
            if !self.keptPhotos.contains(asset.localIdentifier) &&
               !self.deletedPhotos.contains(asset.localIdentifier) {
                self.allPhotos.append(asset)
            }
        }
        
        loadRandomGroup()
    }
    
    private func loadRandomGroup() {
        guard !allPhotos.isEmpty else {
            currentGroup = []
            groupInfoLabel.text = "没有更多照片可浏览"
            collectionView.reloadData()
            return
        }
        
        // 随机选择一组照片
        let availablePhotos = allPhotos.shuffled()
        currentGroup = Array(availablePhotos.prefix(groupSize))
        
        groupInfoLabel.text = "当前组: \(currentGroup.count) 张照片 (随机分组)"
        collectionView.reloadData()
    }
    
    // MARK: - Actions
    @objc private func completeCurrentGroup() {
        let alert = UIAlertController(
            title: "完成当前组",
            message: "您已完成当前组的浏览。是否开始新的一组随机照片？",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "开始新组", style: .default) { _ in
            self.startNewGroup()
        })
        
        present(alert, animated: true)
    }
    
    private func startNewGroup() {
        // 从allPhotos中移除当前组中已处理过的照片
        allPhotos.removeAll { asset in
            currentGroup.contains { $0.localIdentifier == asset.localIdentifier }
        }
        
        if allPhotos.isEmpty {
            showAlert(title: "完成", message: "所有照片都已浏览完毕！")
            currentGroup = []
            collectionView.reloadData()
            groupInfoLabel.text = "所有照片已浏览完成"
        } else {
            loadRandomGroup()
            showToast(message: "新的一组照片已加载")
        }
    }
    
    private func keepPhoto(_ asset: PHAsset) {
        keptPhotos.insert(asset.localIdentifier)
        saveUserData()
        showToast(message: "照片已保留")
    }
    
    private func deletePhoto(_ asset: PHAsset) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets([asset] as NSArray)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.deletedPhotos.insert(asset.localIdentifier)
                    self.saveUserData()
                    self.showToast(message: "照片已删除")
                } else {
                    self.showAlert(title: "删除失败", message: error?.localizedDescription ?? "未知错误")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    private func showToast(message: String) {
        // 简化的toast实现
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            alert.dismiss(animated: true)
        }
    }
    
    // SHA256 函数（修复后的版本）
    private func sha256(data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension PhotoBrowseViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentGroup.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GroupPhotoCell", for: indexPath) as! GroupPhotoCell
        let asset = currentGroup[indexPath.item]
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

// MARK: - GroupPhotoCellDelegate
extension PhotoBrowseViewController: GroupPhotoCellDelegate {
    
    func didTapKeep(on asset: PHAsset) {
        let alert = UIAlertController(
            title: "保留照片",
            message: "确定要保留这张照片吗？",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "保留", style: .default) { _ in
            self.keepPhoto(asset)
        })
        
        present(alert, animated: true)
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
