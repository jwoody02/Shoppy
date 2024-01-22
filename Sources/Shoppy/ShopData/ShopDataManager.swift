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


    /**
     Fetches collections with pagination.

     - Parameters:
            [optional]
         - limit: The maximum number of collections to fetch. Default is 25.
         - shouldSaveToDataStore: A boolean value indicating whether the fetched collections should be saved to the data store. Default is true.
         - customCursor: A custom cursor to use for pagination. Default is nil.
         - completion: A closure that is called when the fetch operation is completed. It takes an optional array of CollectionViewModel as its parameter.
    */
    @discardableResult
    public func fetchCollections(
            limit: Int = 25,
            shouldSaveToDataStore: Bool = true,
            customCursor: String? = nil,
            completion: @escaping ([CollectionViewModel]?) -> Void
        ) -> Task? {
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

    /**
     Fetches products within a collection with pagination.

     - Parameters:
          [required]
         - collection: The collection view model representing the collection.

          [optional]
         - limit: The maximum number of products to fetch (default is 25).
         - shouldSaveToDataStore: A boolean value indicating whether the fetched products should be saved to the data store (default is true).
         - customCursor: A custom cursor to use for fetching products.
         - filter: The product filter to apply (default is an empty filter).
         - sortKey: The sort key to use for sorting the products within the collection (default is the collection's default sort key).
         - shouldReverse: A boolean value indicating whether the products should be sorted in reverse order (default is nil).
         - keyword: A keyword to filter the products by (default is nil).
         - completion: A closure that is called when the fetch operation is complete. It takes an optional array of `ProductViewModel` objects as its parameter.
    */
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

    // Custom helper function to fetch CollectionViewModel from a collection handle
    @discardableResult
    public func fetchCollectionByHandle(
        from collectionHandle: String,
        productLimit: Int32 = 50,
        customCursor: String? = nil,
        filter: Storefront.ProductFilter = .create(),
        sortKey: Storefront.ProductCollectionSortKeys = .collectionDefault,
        shouldReverse: Bool? = nil,
        keyword: String? = nil,
        completion: @escaping (CollectionViewModel?
    ) -> Void) -> Task? {
        
        let query = ClientQuery.queryForCollectionWithHandle(
            handle: collectionHandle,
            limit: productLimit, after: customCursor,
            filters: [filter],
            sortKey: sortKey,
            shouldReverse: shouldReverse
        )

       let task = self.client?.getClient().queryGraphWith(query) { response, error in
           if let collection = response?.collection {
                completion(CollectionViewModel(collection: collection))
            } else {
                completion(nil)
            }
        }
        task?.resume()
        return task
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

    // remove data for collection id
    public func resetCollectionData(for collectionId: String) {
        self.collections.removeAll(where: { $0.id == collectionId })
        self.filteredProductsByQuery = self.filteredProductsByQuery.filter { $0.key.collectionId != collectionId }
        self.productCursorByFilteredQuery = self.productCursorByFilteredQuery.filter { $0.key.collectionId != collectionId }
        self.hasReachedEndOfFilteredQuery = self.hasReachedEndOfFilteredQuery.filter { $0.key.collectionId != collectionId }
    }

    // remove all data from data store
    public static func resetSharedCollectionDataStore() {
        ShopDataManager.shared.collections = []
        ShopDataManager.shared.filteredProductsByQuery = [:]
        ShopDataManager.shared.productCursorByFilteredQuery = [:]
        ShopDataManager.shared.hasReachedEndOfFilteredQuery = [:]
        ShopDataManager.shared.collectionCursor = nil
    }

    // MARK: - Fuzzy Search

    private var searchCollectionsCache: [String: [CollectionViewModel]] = [:] // Cache for collections

    public func resetSearchCache() {
        searchCollectionsCache = [:]
    }

    /**
     This method searches for products in all collections using a given search term.

     - Parameters:
            [required]
         - searchTerm: The search term to filter the products.
         - completion: A closure that is called when the search is complete. It takes an optional array of `ProductViewModel` as a parameter.

    */
    public func searchForProductsInAllCollections(
        with searchTerm: String,
        collectionCountLimit: Int = 150,
        productLimitPerCollection: Int = 150,
        completion: @escaping ([ProductViewModel]?) -> Void
    ) {
        if let cachedCollections = searchCollectionsCache["collections"] {
            // Use cached data to filter and completion
            completion(filterProducts(in: cachedCollections, with: searchTerm))
        } else {
            // Fetch product data and update cache
            client?.fetchCollections(limit: collectionCountLimit, after: nil, productLimit: productLimitPerCollection, productCursor: nil) { [weak self] result in
                guard let self = self else { return }
                if let collections = result {
                    // Update cache, removing duplicate collections
                    // TODO: - Sort items so its the same each time
                    var collections = Array(Set(collections.items))

                    // filter products and completion
                    var filteredProducts = Array(Set(self.filterProducts(in: collections, with: searchTerm)))
                    filteredProducts.sort { $0.title < $1.title }
                    self.searchCollectionsCache["collections"] = collections
                    
                    completion(filteredProducts)
                } else {
                    // No collections found
                    completion(nil)
                }
            }
        }
    }


    /**
     Searches for products in a given collection with a specified search term.

     - Parameters:
            [required]
        - searchTerm: The search term to match against product titles and summaries.
        - collection: The collection to search within.

            [optional]
        - limit: The maximum number of products to retrieve. Default is 25.
        - completion: A closure that is called when the search is complete. It takes an optional array of `ProductViewModel` objects as its parameter.

     */
    public func searchForProductsInCollection(
        with searchTerm: String,
        collection: CollectionViewModel,
        limit: Int = 25,
        completion: @escaping ([ProductViewModel]?) -> Void
    ) {
        client?.fetchProducts(in: collection, after: nil, filters: [], sortKey: .collectionDefault, shouldReverse: nil) { result in
            if let products = result {
                if searchTerm.isEmpty || searchTerm.replacingOccurrences(of: " ", with: "") == "" {
                    // Return all products without filtering
                    completion(products.items)
                } else {
                    let filteredProducts = products.items.filter { product in
                        return self.isFuzzyMatch(string: product.title, with: searchTerm) || self.isFuzzyMatch(string: product.summary, with: searchTerm)
                    }

                    // Remove duplicate products
                    let filteredProductsSet = Array(Set(filteredProducts))
                    completion(filteredProductsSet)
                }
            } else {
                completion(nil)
            }
        }
    }

    private func filterProducts(
        in collections: [CollectionViewModel],
        with searchTerm: String
    ) -> [ProductViewModel] {
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

        // Lower score means closer match. 0.0 is an exact match.
        return results?.score ?? 1.0 <= 0.3
    }


}

public extension Notification.Name {
    static let collectionsUpdatedNotification = Notification.Name("ShopDataManagerCollectionsUpdated")
    static let productsUpdatedNotification = Notification.Name("ShopDataManagerProductsUpdated")
}
