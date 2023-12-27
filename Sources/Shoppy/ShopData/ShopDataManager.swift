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

    // product collections
    private var collections: [CollectionViewModel] = []
    private var collectionCursor: String?
    private var reachedEndOfCollections = false


    // dictionaries for new query architecture
    private var filteredProductsByQuery: [FilteredProductQuery: [ProductViewModel]] = [:]
    private var productCursorByFilteredQuery: [FilteredProductQuery: String?] = [:]
    private var hasReachedEndOfFilteredQuery: [FilteredProductQuery: Bool?] = [:]


    // shared client
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

                    // if products were returned, save them to the data store
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
    public func fetchProducts(
            in collection: CollectionViewModel, limit: Int = 25,
            shouldSaveToDataStore: Bool = true,
            customCursor: String? = nil,
            filter: Storefront.ProductFilter = .create(),
            sortKey: Storefront.ProductCollectionSortKeys = .collectionDefault,
            shouldReverse: Bool? = nil,
            keyword: String? = nil,
            completion: @escaping ([ProductViewModel]?
        ) -> Void) -> Task? {

        // Define the current query + cursor
        let query = FilteredProductQuery(collectionId: collection.id, filter: filter, sortKey: sortKey, shouldReverseSort: shouldReverse, keyword: keyword)
        var currentCursor = productCursorByFilteredQuery[query] ?? nil
        if let cursor = customCursor {
            currentCursor = cursor.isEmpty ? nil : customCursor
        }

        // Fetch products based on the current query + cursor
        return client?.fetchProducts(in: collection, after: currentCursor, filters: [filter], sortKey: sortKey, shouldReverse: shouldReverse) { [weak self] result in
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

    // check if already fetched all products for the passed filtered product query
    public func hasReachedEndOfCollection(query: FilteredProductQuery) -> Bool {
        if let hasReachedEnd = hasReachedEndOfFilteredQuery[query] as? Bool {
            return hasReachedEnd
        }
        return false
    }

    // Function to get products for a specific collection
    public func products(in query: FilteredProductQuery) -> [ProductViewModel]? {
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

    // MARK: - Search
    private var searchCollectionsCache: [String: [CollectionViewModel]] = [:] // Cache for collections
    public func searchForProductsInAllCollections(with searchTerm: String, completion: @escaping ([ProductViewModel]?) -> Void) {
        if let cachedCollections = searchCollectionsCache["collections"] {
            // Use cached data
            completion(filterProducts(in: cachedCollections, with: searchTerm))
        } else {
            // Fetch product data and update cache
            client?.fetchCollections(limit: 50, after: nil, productLimit: 150, productCursor: nil) { result in
                if let collections = result {
                    self.searchCollectionsCache["collections"] = collections.items
                    completion(self.filterProducts(in: collections.items, with: searchTerm))
                } else {
                    completion(nil)
                }
            }
        }
    }

    private func filterProducts(in collections: [CollectionViewModel], with searchTerm: String) -> [ProductViewModel] {
        var products: [ProductViewModel] = []
        collections.forEach { collection in
            collection.products.items.forEach { product in
                if self.isFuzzyMatch(string: product.title, with: searchTerm) || self.isFuzzyMatch(string: product.summary, with: searchTerm) {
                    products.append(product)
                }
            }
        }
        return products
    }

    private func isFuzzyMatch(string: String, with searchTerm: String) -> Bool {
        let fuse = Fuse()
        let results = fuse.search(searchTerm, in: string)
        // You can adjust the score threshold according to your needs.
        // Lower score means closer match. 0.0 is an exact match.
        return results?.score ?? 1.0 <= 0.3
    }


}

public extension Notification.Name {
    static let collectionsUpdatedNotification = Notification.Name("ShopDataManagerCollectionsUpdated")
    static let productsUpdatedNotification = Notification.Name("ShopDataManagerProductsUpdated")
}
