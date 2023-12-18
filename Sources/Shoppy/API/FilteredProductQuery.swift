//
//  File.swift
//  
//
//  Created by Jordan Wood on 12/18/23.
//

import Foundation
import Buy

// Helper struct for hashing a product fetch
// based on collectionid, filters, and the sort key
struct FilteredProductQuery: Hashable {
    let collectionId: String
    let filterString: String
    let sortKey: Storefront.ProductCollectionSortKeys

    init(collectionId: String, filter: Storefront.ProductFilter, sortKey: Storefront.ProductCollectionSortKeys) {
        self.collectionId = collectionId
        self.filterString = FilterHelper.uniqueIdentifier(for: filter)
        self.sortKey = sortKey
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(collectionId)
        hasher.combine(filterString)
        hasher.combine(sortKey)
    }

    static func == (lhs: FilteredProductQuery, rhs: FilteredProductQuery) -> Bool {
        return lhs.collectionId == rhs.collectionId &&
               lhs.filterString == rhs.filterString &&
               lhs.sortKey == rhs.sortKey
    }
}

class FilterHelper {
    static func uniqueIdentifier(for filter: Storefront.ProductFilter) -> String {
        var identifier = ""

        switch filter.available {
        case .value(let available):
            if let available = available {
                identifier += "available:\(available),"
            }
        case .undefined:
            break
        }

        switch filter.variantOption {
        case .value(let variantOption):
            if let variantOption = variantOption {
                identifier += "variantOption:\(variantOption.name)-\(variantOption.value),"
            }
        case .undefined:
            break
        }
        
        switch filter.productType {
        case .value(let prodType):
            if let productType = prodType {
                identifier += "productType:\(productType.hashValue),"
            }
        case .undefined:
            break
        }
        
        switch filter.productVendor {
        case .value(let t):
            if let prodVendor = t {
                identifier += "productVendor:\(prodVendor),"
            }
        case .undefined:
            break
        }
        
        switch filter.price {
        case .value(let t):
            if let price = t {
                identifier += "price:\(price.min)-\(price.max),"
            }
        case .undefined:
            break
        }
        
        switch filter.productMetafield {
        case .value(let t):
            if let metaField = t {
                identifier += "prodMetaField:\(metaField.key)-\(metaField.value),"
            }
        case .undefined:
            break
        }
        
        switch filter.variantMetafield {
        case .value(let t):
            if let metaField = t {
                identifier += "variantMetaField:\(metaField.key)-\(metaField.value),"
            }
        case .undefined:
            break
        }
        
        switch filter.tag {
        case .value(let t):
            if let tag = t {
                identifier += "tag:\(tag),"
            }
        case .undefined:
            break
        }
        
        return identifier
    }
}
