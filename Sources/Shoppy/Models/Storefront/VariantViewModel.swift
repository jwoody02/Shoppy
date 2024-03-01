//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Foundation
import Buy

public final class SelectedOptionViewModel: ViewModel {
    
    public typealias ModelType = Storefront.SelectedOption
    
    public let model: ModelType
    
    public let name:  String
    public let value: String
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required public init(from model: ModelType) {
        self.model = model
        
        self.name  = model.name
        self.value = model.value
    }
}


public final class VariantViewModel: ViewModel {
    
    public typealias ModelType = Storefront.ProductVariantEdge
    
    public let model:  ModelType
    public let cursor: String
    
    public let id:     String
    public let title:  String
    public let price:  Decimal
    public let compareAtPrice: Decimal?
    
    public let currentlyNotInStock: Bool

    public let options: [SelectedOptionViewModel]
    public let featureImageUrl: URL?
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required public init(from model: ModelType) {
        self.model  = model
        self.cursor = model.cursor
        
        self.id     = model.node.id.rawValue
        self.title  = model.node.title
        self.price  = model.node.price.amount
        
        self.currentlyNotInStock = model.node.currentlyNotInStock || !model.node.availableForSale
        self.options = model.node.selectedOptions.map { SelectedOptionViewModel(from: $0) }
        self.featureImageUrl = model.node.image?.url
        
        self.compareAtPrice = model.node.compareAtPrice?.amount
    }
}

extension Storefront.ProductVariantEdge: ViewModeling {
    public typealias ViewModelType = VariantViewModel
}
