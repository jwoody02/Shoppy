//
//  PaginatedArray.swift
//
//
//  Created by Jordan Wood on 11/25/23.
//


import Buy

struct PageableArray<T: ViewModel> {
    
    private(set) var items: [T]
    
    var hasNextPage: Bool {
        return pageInfo.hasNextPage
    }
    
    var hasPreviousPage: Bool {
        return pageInfo.hasPreviousPage
    }
    
    public var pageInfo: Storefront.PageInfo
    
    // ----------------------------------
    //  MARK: - Init -
    //
    init(with items: [T], pageInfo: Storefront.PageInfo) {
        self.items    = items
        self.pageInfo = pageInfo
    }
    
    init<M>(with items: [M], pageInfo: Storefront.PageInfo) where M: ViewModeling, M.ViewModelType == T {
        self.items    = items.viewModels
        self.pageInfo = pageInfo
    }
    
    // ----------------------------------
    //  MARK: - Adding -
    //
    mutating func appendPage(from pageableArray: PageableArray<T>) {
        self.items.append(contentsOf: pageableArray.items)
        self.pageInfo = pageableArray.pageInfo
    }
}
