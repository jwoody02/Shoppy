//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//
import Foundation
import Buy

public final class CollectionViewModel: ViewModel {
    
    public let model:       Storefront.Collection
    public let cursor:      String?
    
    public let id:          String
    public let title:       String
    public let description: String
    public let imageURL:    URL?
    public let updatedAt:   Date
    public var products:    PageableArray<ProductViewModel>
    
    // ----------------------------------
    //  MARK: - Init With Collection Edge -
    //
    public init(fromEdge model: Storefront.CollectionEdge) {
        self.model       = model.node
        self.cursor      = model.cursor
        
        self.id          = model.node.id.rawValue
        self.title       = model.node.title
        self.imageURL    = model.node.image?.url
        self.description = model.node.descriptionHtml
        
        self.products    = PageableArray(
            with:     model.node.products.edges,
            pageInfo: model.node.products.pageInfo
        )
        
        self.updatedAt = model.node.updatedAt
    }
    
    // ----------------------------------
    //  MARK: - Init With Collection -
    //
    public init(from model: Storefront.Collection) {
        self.model       = model
        self.cursor      = nil // individual collection don't have a cursor
        
        self.id          = model.id.rawValue
        self.title       = model.title
        self.imageURL    = model.image?.url
        self.description = model.descriptionHtml
        
        self.products    = PageableArray(
            with:     model.products.edges,
            pageInfo: model.products.pageInfo
        )
        
        self.updatedAt = model.updatedAt
    }
}

extension CollectionViewModel: Hashable {
    public static func == (lhs: CollectionViewModel, rhs: CollectionViewModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
