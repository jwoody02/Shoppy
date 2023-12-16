//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Foundation
import Buy

struct Currency {

    private static let formatter: NumberFormatter = {
        let formatter         = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()
    
    static func stringFrom(_ decimal: Decimal, currency: String? = nil) -> String {
        return self.formatter.string(from: decimal as NSDecimalNumber)!
    }
}

public final class ProductViewModel: ViewModel {
    
    public typealias ModelType = Storefront.ProductEdge
    
    public let model:    ModelType
    public let cursor:   String
    
    public let id:       String
    public let handle:   String
    public let title:    String
    public let summary:  String
    public let price:    String
    public let compareToPriceRange: (Decimal, Decimal)
    public let images:   PageableArray<ImageViewModel>
    public let variants: PageableArray<VariantViewModel>
    
    public let availableForSale: Bool
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required public init(from model: ModelType) {
        self.model    = model
        self.cursor   = model.cursor
        
        let variants = model.node.variants.edges.viewModels.sorted {
            $0.price < $1.price
        }
        
        let lowestPrice = variants.first?.price
        
        self.id       = model.node.id.rawValue
        self.title    = model.node.title
        self.summary  = model.node.descriptionHtml
        self.price    = lowestPrice == nil ? "No price" : Currency.stringFrom(lowestPrice!)
        
        self.images   = PageableArray(
            with:     model.node.images.edges,
            pageInfo: model.node.images.pageInfo
        )
        
        self.variants = PageableArray(
            with:     model.node.variants.edges,
            pageInfo: model.node.variants.pageInfo
        )
        
        self.compareToPriceRange = (
            model.node.compareAtPriceRange.minVariantPrice.amount,
            model.node.compareAtPriceRange.maxVariantPrice.amount
        )
        self.availableForSale = model.node.availableForSale
        self.handle = model.node.handle
    }
}

extension Storefront.ProductEdge: ViewModeling {
    public typealias ViewModelType = ProductViewModel
}
