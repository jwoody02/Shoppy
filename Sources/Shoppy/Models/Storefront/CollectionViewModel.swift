//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//

import Foundation
import Buy

public final class CollectionViewModel: ViewModel {
    
    
    public typealias ModelType = Storefront.CollectionEdge
    
    public let model:       ModelType
    public let cursor:      String
    
    public let id:          String
    public let title:       String
    public let description: String
    public let imageURL:    URL?
    public var products:    PageableArray<ProductViewModel>
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required public init(from model: ModelType) {
        self.model       = model
        self.cursor      = model.cursor
    
        self.id          = model.node.id.rawValue
        self.title       = model.node.title
        self.imageURL    = model.node.image?.url
        self.description = model.node.descriptionHtml
        
        self.products    = PageableArray(
            with:     model.node.products.edges,
            pageInfo: model.node.products.pageInfo
        )
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

extension Storefront.CollectionEdge: ViewModeling {
    public typealias ViewModelType = CollectionViewModel
}
