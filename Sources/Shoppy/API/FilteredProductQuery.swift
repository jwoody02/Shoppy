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
public struct FilteredProductQuery: Hashable {
    public let collectionId: String
    public let filterObject: Storefront.ProductFilter
    public let filterString: String
    public let sortKey: Storefront.ProductCollectionSortKeys
    public let shouldReverseSort: Bool?
    public let keyword: String?

    public init(collectionId: String, filter: Storefront.ProductFilter, sortKey: Storefront.ProductCollectionSortKeys, shouldReverseSort: Bool? = nil, keyword: String? = nil) {
        self.collectionId = collectionId
        self.filterObject = filter
        self.filterString = FilterHelper.uniqueIdentifier(for: filter)
        self.sortKey = sortKey
        self.shouldReverseSort = shouldReverseSort
        self.keyword = keyword
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(collectionId)
        hasher.combine(filterString)
        hasher.combine(sortKey)
        hasher.combine(shouldReverseSort)
        hasher.combine(keyword)
    }

    public static func == (lhs: FilteredProductQuery, rhs: FilteredProductQuery) -> Bool {
        return lhs.collectionId == rhs.collectionId &&
               lhs.filterString == rhs.filterString &&
               lhs.sortKey == rhs.sortKey &&
               lhs.shouldReverseSort == rhs.shouldReverseSort &&
               lhs.keyword ==  rhs.keyword
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
