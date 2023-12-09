//
//  File.swift
//  
//
//  Created by Jordan Wood on 12/7/23.
//

import Foundation
import Buy

public class FilterManager {
    private var filters: [Storefront.ProductFilter] = []

    public var activeFilterCount: Int {
        filters.count
    }

    public func addFilter(_ filter: Storefront.ProductFilter) {
        filters.append(filter)
    }

    public func removeFilter(_ filter: Storefront.ProductFilter) {
        filters.removeAll { $0 === filter }
    }
    
    public func getActiveFilters() -> [Storefront.ProductFilter] {
        return self.filters
    }
}


