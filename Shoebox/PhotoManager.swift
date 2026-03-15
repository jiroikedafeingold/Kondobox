//
//  PhotoManager.swift
//  Shoebox
//
//  Created by Jiro Feingold
//  Copyright (c) 2026 Jiro Feingold. All rights reserved.
//
//  Core photo management service. Handles PhotoKit authorization,
//  loading random unreviewed photos, image caching, album creation,
//  deletion, favoriting, and tracking reviewed photo history.
//

import SwiftUI
import Photos
import UIKit

struct PhotoItem: Identifiable, Equatable {
    let id: String
    let asset: PHAsset

    static func == (lhs: PhotoItem, rhs: PhotoItem) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
class PhotoManager: ObservableObject {
    @Published var photos: [PhotoItem] = []
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var isLoading = false

    private let imageManager = PHCachingImageManager()
    private static let reviewedKey = "reviewedPhotoIDs"

    var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .limited
    }

    init() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    private var reviewedIDs: Set<String> {
        get {
            Set(UserDefaults.standard.stringArray(forKey: Self.reviewedKey) ?? [])
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: Self.reviewedKey)
        }
    }

    private func markReviewed(_ id: String) {
        var ids = reviewedIDs
        ids.insert(id)
        reviewedIDs = ids
    }

    func requestAuthorization() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        authorizationStatus = status
    }

    func loadRandomPhotos(count: Int = 10) {
        guard isAuthorized else { return }
        isLoading = true

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        guard allPhotos.count > 0 else {
            isLoading = false
            return
        }

        let reviewed = reviewedIDs

        // Build list of eligible indices (not yet reviewed)
        var eligible: [Int] = []
        for i in 0..<allPhotos.count {
            let asset = allPhotos.object(at: i)
            if !reviewed.contains(asset.localIdentifier) && !asset.isFavorite {
                eligible.append(i)
            }
        }

        guard !eligible.isEmpty else {
            photos = []
            isLoading = false
            return
        }

        eligible.shuffle()
        let maxCount = count == 0 ? eligible.count : min(count, eligible.count)

        var items: [PhotoItem] = []
        for i in 0..<maxCount {
            let asset = allPhotos.object(at: eligible[i])
            items.append(PhotoItem(id: asset.localIdentifier, asset: asset))
        }

        photos = items
        isLoading = false
    }

    func loadImage(for asset: PHAsset, targetSize: CGSize, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        imageManager.requestImage(
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

    func deletePhoto(_ item: PhotoItem) async -> Bool {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets([item.asset] as NSFastEnumeration)
            }
            markReviewed(item.id)
            photos.removeAll { $0.id == item.id }
            return true
        } catch {
            print("Failed to delete photo: \(error)")
            return false
        }
    }

    func addToAlbum(_ item: PhotoItem, albumName: String = "Shoebox") async -> Bool {
        do {
            let album = try await fetchOrCreateAlbum(named: albumName)
            try await PHPhotoLibrary.shared().performChanges {
                guard let addRequest = PHAssetCollectionChangeRequest(for: album) else { return }
                addRequest.addAssets([item.asset] as NSFastEnumeration)
            }
            markReviewed(item.id)
            photos.removeAll { $0.id == item.id }
            return true
        } catch {
            print("Failed to add to album: \(error)")
            return false
        }
    }

    private func fetchOrCreateAlbum(named name: String) async throws -> PHAssetCollection {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", name)
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

        if let existing = collections.firstObject {
            return existing
        }

        var placeholder: PHObjectPlaceholder?
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
            placeholder = request.placeholderForCreatedAssetCollection
        }

        guard let placeholder = placeholder,
              let collection = PHAssetCollection.fetchAssetCollections(
                withLocalIdentifiers: [placeholder.localIdentifier], options: nil
              ).firstObject else {
            throw NSError(domain: "Shoebox", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create album"])
        }

        return collection
    }

    func favoritePhoto(_ item: PhotoItem) async -> Bool {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetChangeRequest(for: item.asset)
                request.isFavorite = true
            }
            markReviewed(item.id)
            photos.removeAll { $0.id == item.id }
            return true
        } catch {
            print("Failed to favorite photo: \(error)")
            return false
        }
    }

    func removeFromQueue(_ item: PhotoItem) {
        markReviewed(item.id)
        photos.removeAll { $0.id == item.id }
    }

    /// Returns the total number of photos in the library, usable from any context.
    nonisolated static func photoLibraryCount() -> Int {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else { return 0 }
        let result = PHAsset.fetchAssets(with: .image, options: nil)
        return result.count
    }

    /// Check if there are new photos since the last review.
    nonisolated static func hasNewPhotosSinceLastReview() -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else { return false }

        let lastReviewDate = UserDefaults.standard.object(forKey: "lastReviewDate") as? Date ?? .distantPast

        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "creationDate > %@", lastReviewDate as NSDate)
        fetchOptions.fetchLimit = 1
        let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        return result.count > 0
    }

    /// Number of photos that have been reviewed.
    var reviewedCount: Int {
        reviewedIDs.count
    }

    /// Clear the reviewed history so all photos become eligible again.
    func resetReviewHistory() {
        reviewedIDs = []
    }

    /// Mark the current time as the last review.
    func markReviewCompleted() {
        UserDefaults.standard.set(Date(), forKey: "lastReviewDate")
    }
}
