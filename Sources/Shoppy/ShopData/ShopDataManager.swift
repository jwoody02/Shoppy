//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/27/23.
//

import Foundation
import Buy

public final class ShopDataManager {
    static let shared = ShopDataManager()

    private var collections: [CollectionViewModel] = []
    private var productsByCollection: [String: [ProductViewModel]] = [:]
    private var productCursorByCollection: [String: String?] = [:]

    private var collectionCursor: String?
    private let client: Client? = Client.shared

    // Fetch collections with pagination
    @discardableResult
    func fetchCollections(limit: Int = 25, completion: @escaping (PageableArray<CollectionViewModel>?) -> Void) -> Task? {
        return client?.fetchCollections(limit: limit, after: collectionCursor, productLimit: 25, productCursor: nil) { [weak self] result in
            guard let self = self else { return }

            if let collections = result {
                self.collections.append(contentsOf: collections.items)
                self.collectionCursor = collections.pageInfo.hasNextPage ? collections.items.last?.cursor : nil
                // Initialize product arrays and cursors for each collection
                collections.items.forEach {
                    self.productsByCollection[$0.id] = []
                    self.productCursorByCollection[$0.id] = nil
                }
            }

            completion(result)
        }
    }

    // Fetch products within a collection with pagination
    @discardableResult
    func fetchProducts(in collection: CollectionViewModel, limit: Int = 25, completion: @escaping (PageableArray<ProductViewModel>?) -> Void) -> Task? {
        let currentCursor = productCursorByCollection[collection.id] ?? nil
        return client?.fetchProducts(in: collection, limit: limit, after: currentCursor) { [weak self] result in
            guard let self = self else { return }

            if let products = result {
                // Append products to the correct collection
                self.productsByCollection[collection.id]?.append(contentsOf: products.items)
                // Update product cursor for this collection
                self.productCursorByCollection[collection.id] = products.pageInfo.hasNextPage ? products.items.last?.cursor : nil
            }

            completion(result)
        }
    }

    // Function to get products for a specific collection
    func products(in collection: CollectionViewModel) -> [ProductViewModel]? {
        return productsByCollection[collection.id]
    }
}
