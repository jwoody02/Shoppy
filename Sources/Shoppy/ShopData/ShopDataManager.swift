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
    
    private var reachedEndOfCollections = false
    private var hasReachedEndOfCollection: [String: Bool?] = [:]
    
    private let client: Client? = Client.shared


    
    // Fetch collections with pagination
    @discardableResult
    public func fetchCollections(limit: Int = 25, shouldSaveToDataStore: Bool = true, customCursor: String? = nil, completion: @escaping ([CollectionViewModel]?) -> Void) -> Task? {
        var currentCursor = collectionCursor
        if let cursor = customCursor {
            if cursor == "" {
                currentCursor = nil
            } else {
                currentCursor = customCursor
            }
        }
        return client?.fetchCollections(limit: limit, after: currentCursor, productLimit: 25, productCursor: nil) { [weak self] result in
            guard let self = self else { return }
            
            if let collections = result, !reachedEndOfCollections, shouldSaveToDataStore {
                self.collections.append(contentsOf: collections.items)
                if let cursor = collections.items.last?.cursor {
                    self.collectionCursor = cursor
                } else {
                    self.reachedEndOfCollections = true
                }
                
                // Initialize product arrays and cursors for each collection
                collections.items.forEach {
                    self.productsByCollectionId[$0.id] = []
                    self.productCursorByCollection[$0.id] = nil
                    if $0.products.items.isEmpty == false {
                        self.productsByCollectionId[$0.id] = $0.products.items
                        self.productCursorByCollection[$0.id] = $0.products.items.last?.cursor
                    }
                    
                }
            }
            NotificationCenter.default.post(name: .collectionsUpdatedNotification, object: nil)
            
            if let result = result {
                completion(result.getItems())
            } else {
                completion(nil)
            }
        }
    }

    // Fetch products within a collection with pagination
    @discardableResult
    public func fetchProducts(in collection: CollectionViewModel, limit: Int = 25, shouldSaveToDataStore: Bool = true, customCursor: String? = nil, completion: @escaping ([ProductViewModel]?) -> Void) -> Task? {
        var currentCursor = productCursorByCollection[collection.id] ?? nil
        if let cursor = customCursor {
            if cursor == "" {
                currentCursor = nil
            } else {
                currentCursor = customCursor
            }
        }
        return client?.fetchProducts(in: collection, limit: limit, after: currentCursor) { [weak self] result in
            guard let self = self else { return }

            if let products = result, (self.hasReachedEndOfCollection[collection.id] == nil), shouldSaveToDataStore  {
                // Append products to the correct collection
                self.productsByCollectionId[collection.id]?.append(contentsOf: products.items)
                self.productCursorByCollection[collection.id] = products.items.last?.cursor
                
                // reached end of collection
                if !products.pageInfo.hasNextPage {
                    self.hasReachedEndOfCollection[collection.id] = true
                }
                
            }
            NotificationCenter.default.post(name: .productsUpdatedNotification, object: nil, userInfo: ["collectionId": collection.id])
                
            completion(result?.items)
        }
    }
    
    // check if reached end of collection
    public func hasReachedEndOfCollection(id collection: String) -> Bool {
        if let hasReached = self.hasReachedEndOfCollection[collection] {
            return hasReached ?? false
        }
        return false
    }
    
    // check if already fetched all collections
    public func hasReachedEndOfCollections() -> Bool {
        return self.reachedEndOfCollections
    }
    
    // check if already fetched all products for this collection
    public func reachedEndOfColletion(collectionId: String) -> Bool {
        if let hasReachedEnd = hasReachedEndOfCollection[collectionId] as? Bool {
            return hasReachedEnd
        }
        return false
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
    
    public static func resetSharedCollectionDataStore() {
        ShopDataManager.shared.collections = []
        ShopDataManager.shared.productsByCollectionId = [:]
        ShopDataManager.shared.productCursorByCollection = [:]
        ShopDataManager.shared.hasReachedEndOfCollection = [:]
        ShopDataManager.shared.collectionCursor = nil
    }
}

public extension Notification.Name {
    static let collectionsUpdatedNotification = Notification.Name("ShopDataManagerCollectionsUpdated")
    static let productsUpdatedNotification = Notification.Name("ShopDataManagerProductsUpdated")
}
