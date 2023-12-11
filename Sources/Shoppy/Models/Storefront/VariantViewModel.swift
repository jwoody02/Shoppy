//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Foundation
import Buy

public final class VariantViewModel: ViewModel {
    
    public typealias ModelType = Storefront.ProductVariantEdge
    
    public let model:  ModelType
    public let cursor: String
    
    public let id:     String
    public let title:  String
    public let price:  Decimal
    
    public let currentlyNotInStock: Bool
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required public init(from model: ModelType) {
        self.model  = model
        self.cursor = model.cursor
        
        self.id     = model.node.id.rawValue
        self.title  = model.node.title
        self.price  = model.node.price.amount
        
        self.currentlyNotInStock = model.node.currentlyNotInStock
    }
}

extension Storefront.ProductVariantEdge: ViewModeling {
    public typealias ViewModelType = VariantViewModel
}
