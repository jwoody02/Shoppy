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
    private var collectionCursor: String?
    
    private var reachedEndOfCollections = false
    
    
    // dictionaries for new query architecture
    private var filteredProductsByQuery: [FilteredProductQuery: [ProductViewModel]] = [:]
    private var productCursorByFilteredQuery: [FilteredProductQuery: String?] = [:]
    private var hasReachedEndOfFilteredQuery: [FilteredProductQuery: Bool?] = [:]

    
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
                    let query = FilteredProductQuery(collectionId: $0.id, filter: .create(), sortKey: .collectionDefault)
                    self.filteredProductsByQuery[query] = []
                    self.productCursorByFilteredQuery[query] = nil
                    if $0.products.items.isEmpty == false {
                        self.filteredProductsByQuery[query] = $0.products.items
                        self.productCursorByFilteredQuery[query] = $0.products.items.last?.cursor
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
    public func fetchProducts(in collection: CollectionViewModel, limit: Int = 25, shouldSaveToDataStore: Bool = true, customCursor: String? = nil, filter: Storefront.ProductFilter = .create(), sortKey: Storefront.ProductCollectionSortKeys = .collectionDefault, completion: @escaping ([ProductViewModel]?) -> Void) -> Task? {
        let query = FilteredProductQuery(collectionId: collection.id, filter: filter, sortKey: sortKey)
        var currentCursor = productCursorByFilteredQuery[query] ?? nil
        if let cursor = customCursor {
            currentCursor = cursor.isEmpty ? nil : customCursor
        }

        // Modify your client fetch call to include filter and sortKey
        return client?.fetchProducts(in: collection, after: currentCursor, filters: [filter], sortKey: sortKey) { [weak self] result in
            guard let self = self else { return }

            if let products = result, (self.hasReachedEndOfFilteredQuery[query] == nil), shouldSaveToDataStore {
                self.filteredProductsByQuery[query, default: []].append(contentsOf: products.items)
                self.productCursorByFilteredQuery[query] = products.items.last?.cursor

                if !products.pageInfo.hasNextPage {
                    self.hasReachedEndOfFilteredQuery[query] = true
                }
            }
            
            completion(result?.items)
        }
    }

    
    // check if already fetched all collections
    public func hasReachedEndOfCollections() -> Bool {
        return self.reachedEndOfCollections
    }
    
    // check if already fetched all products for this collection
    public func hasReachedEndOfCollection(id collection: String, filter: Storefront.ProductFilter = .create(), sortKey: Storefront.ProductCollectionSortKeys = .collectionDefault) -> Bool {
        let query = FilteredProductQuery(collectionId: collection, filter: filter, sortKey: sortKey)
        if let hasReachedEnd = hasReachedEndOfFilteredQuery[query] as? Bool {
            return hasReachedEnd
        }
        return false
    }
    
    // Function to get products for a specific collection
    public func products(in collection: CollectionViewModel, filter: Storefront.ProductFilter, sortBy: Storefront.ProductCollectionSortKeys) -> [ProductViewModel]? {
        let query = FilteredProductQuery(collectionId: collection.id, filter: filter, sortKey: sortBy)
        return filteredProductsByQuery[query]
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
        ShopDataManager.shared.filteredProductsByQuery = [:]
        ShopDataManager.shared.productCursorByFilteredQuery = [:]
        ShopDataManager.shared.hasReachedEndOfFilteredQuery = [:]
        ShopDataManager.shared.collectionCursor = nil
    }
}

public extension Notification.Name {
    static let collectionsUpdatedNotification = Notification.Name("ShopDataManagerCollectionsUpdated")
    static let productsUpdatedNotification = Notification.Name("ShopDataManagerProductsUpdated")
}
