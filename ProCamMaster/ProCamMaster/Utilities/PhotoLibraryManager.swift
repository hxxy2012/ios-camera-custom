//
//  PhotoLibraryManager.swift
//  ProCam Master
//
//  照片库管理器
//  Created by Claude
//

import Foundation
import Photos
import UIKit

class PhotoLibraryManager: ObservableObject {

    static let shared = PhotoLibraryManager()

    // MARK: - Published Properties
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var recentPhotos: [PHAsset] = []

    // MARK: - Initialization
    private init() {
        checkAuthorization()
    }

    // MARK: - Authorization

    /// 检查相册权限
    func checkAuthorization() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    /// 请求相册权限
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
                completion(status == .authorized)
            }
        }
    }

    // MARK: - Save Photos

    /// 保存图片到相册
    func saveImage(_ image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        guard authorizationStatus == .authorized else {
            completion(false, NSError(domain: "PhotoLibrary", code: -1, userInfo: [NSLocalizedDescriptionKey: "没有相册权限"]))
            return
        }

        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }

    /// 保存图片数据到相册
    func saveImageData(_ data: Data, completion: @escaping (Bool, Error?) -> Void) {
        guard authorizationStatus == .authorized else {
            completion(false, NSError(domain: "PhotoLibrary", code: -1, userInfo: [NSLocalizedDescriptionKey: "没有相册权限"]))
            return
        }

        PHPhotoLibrary.shared().performChanges {
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, data: data, options: nil)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }

    /// 保存视频到相册
    func saveVideo(at url: URL, completion: @escaping (Bool, Error?) -> Void) {
        guard authorizationStatus == .authorized else {
            completion(false, NSError(domain: "PhotoLibrary", code: -1, userInfo: [NSLocalizedDescriptionKey: "没有相册权限"]))
            return
        }

        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }

    // MARK: - Fetch Photos

    /// 获取最近的照片
    func fetchRecentPhotos(count: Int = 20) {
        guard authorizationStatus == .authorized else { return }

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = count

        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        var assets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }

        DispatchQueue.main.async { [weak self] in
            self?.recentPhotos = assets
        }
    }

    /// 从PHAsset加载图片
    func loadImage(from asset: PHAsset, targetSize: CGSize = PHImageManagerMaximumSize, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    // MARK: - Create Album

    /// 创建自定义相册
    func createAlbum(named title: String, completion: @escaping (Bool, PHAssetCollection?) -> Void) {
        // 检查相册是否已存在
        if let album = fetchAlbum(named: title) {
            completion(true, album)
            return
        }

        // 创建新相册
        var placeholder: PHObjectPlaceholder?

        PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
            placeholder = request.placeholderForCreatedAssetCollection
        } completionHandler: { success, error in
            var album: PHAssetCollection?

            if success, let localIdentifier = placeholder?.localIdentifier {
                let result = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [localIdentifier], options: nil)
                album = result.firstObject
            }

            DispatchQueue.main.async {
                completion(success, album)
            }
        }
    }

    /// 查找相册
    private func fetchAlbum(named title: String) -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", title)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        return collection.firstObject
    }

    /// 保存图片到指定相册
    func saveImage(_ image: UIImage, to albumTitle: String, completion: @escaping (Bool, Error?) -> Void) {
        createAlbum(named: albumTitle) { success, album in
            guard success, let album = album else {
                completion(false, NSError(domain: "PhotoLibrary", code: -2, userInfo: [NSLocalizedDescriptionKey: "创建相册失败"]))
                return
            }

            var assetPlaceholder: PHObjectPlaceholder?

            PHPhotoLibrary.shared().performChanges {
                // 创建图片资源
                let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                assetPlaceholder = creationRequest.placeholderForCreatedAsset

                // 添加到相册
                if let albumChangeRequest = PHAssetCollectionChangeRequest(for: album),
                   let placeholder = assetPlaceholder {
                    albumChangeRequest.addAssets([placeholder] as NSArray)
                }
            } completionHandler: { success, error in
                DispatchQueue.main.async {
                    completion(success, error)
                }
            }
        }
    }

    // MARK: - Delete Photos

    /// 删除照片
    func deleteAsset(_ asset: PHAsset, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets([asset] as NSArray)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }

    // MARK: - Export

    /// 导出PHAsset为文件
    func exportAsset(_ asset: PHAsset, to url: URL, completion: @escaping (Bool, Error?) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat

        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
            guard let data = data else {
                completion(false, NSError(domain: "PhotoLibrary", code: -3, userInfo: [NSLocalizedDescriptionKey: "导出失败"]))
                return
            }

            do {
                try data.write(to: url)
                completion(true, nil)
            } catch {
                completion(false, error)
            }
        }
    }
}
