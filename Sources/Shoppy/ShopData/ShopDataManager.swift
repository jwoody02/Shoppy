//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/27/23.
//

import Foundation
import Buy

public class ShopDataManager {
    public static let shared = ShopDataManager()

    private var collections: [CollectionViewModel] = []
    private var productsByCollectionId: [String: [ProductViewModel]] = [:]
    private var productCursorByCollection: [String: String?] = [:]

    private var collectionCursor: String?
    private let client: Client? = Client.shared

    // Define notification names
    static let collectionsUpdatedNotification = Notification.Name("ShopDataManagerCollectionsUpdated")
    static let productsUpdatedNotification = Notification.Name("ShopDataManagerProductsUpdated")

    
    // Fetch collections with pagination
    @discardableResult
    public func fetchCollections(limit: Int = 25, completion: @escaping (Bool) -> Void) -> Task? {
        return client?.fetchCollections(limit: limit, after: collectionCursor, productLimit: 25, productCursor: nil) { [weak self] result in
            guard let self = self else { return }

            if let collections = result {
                self.collections.append(contentsOf: collections.items)
                self.collectionCursor = collections.pageInfo.hasNextPage ? collections.items.last?.cursor : nil
                // Initialize product arrays and cursors for each collection
                collections.items.forEach {
                    self.productsByCollectionId[$0.id] = []
                    self.productCursorByCollection[$0.id] = nil
                    if $0.products.items.isEmpty == false {
                        self.productCursorByCollection[$0.id] = $0.products.items.last?.cursor
                    }
                }
            }
            NotificationCenter.default.post(name: ShopDataManager.collectionsUpdatedNotification, object: nil)
            
            if let _ = result {
                completion(true)
            } else {
                completion(false)
            }
        }
    }

    // Fetch products within a collection with pagination
    @discardableResult
    public func fetchProducts(in collection: CollectionViewModel, limit: Int = 25, completion: @escaping ([ProductViewModel]?) -> Void) -> Task? {
        let currentCursor = productCursorByCollection[collection.id] ?? nil
        return client?.fetchProducts(in: collection, limit: limit, after: currentCursor) { [weak self] result in
            guard let self = self else { return }

            if let products = result {
                // Append products to the correct collection
                self.productsByCollectionId[collection.id]?.append(contentsOf: products.items)
                // Update product cursor for this collection
                self.productCursorByCollection[collection.id] = products.pageInfo.hasNextPage ? products.items.last?.cursor : nil
            }
            NotificationCenter.default.post(name: ShopDataManager.productsUpdatedNotification, object: nil, userInfo: ["collectionId": collection.id])
                
            completion(result?.items)
        }
    }

    // Function to get products for a specific collection
    public func products(in collection: CollectionViewModel) -> [ProductViewModel]? {
        return productsByCollectionId[collection.id]
    }
    
    // return the number of collections loaded
    public func numberOfCollectionsLoaded() -> Int {
        return self.collections.count
    }
    
    // return optional collection at index
    public func collectionAtIndex(index: Int) -> CollectionViewModel? {
        if index > self.collections.count - 1 {
            return nil
        }
        return self.collections[index]
    }
    
    public func resetCollectionDataStore() {
        self.collections = []
        self.productsByCollectionId = [:]
        self.productCursorByCollection = [:]

        self.collectionCursor = nil
    }
}
