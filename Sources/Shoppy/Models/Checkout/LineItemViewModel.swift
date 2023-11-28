//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Foundation
import Buy

public final class LineItemViewModel: ViewModel {
    
    public typealias ModelType = Storefront.CheckoutLineItemEdge
    
    public let model:    ModelType
    public let cursor:   String
    
    public let variantID:           String?
    public let title:               String
    public let quantity:            Int
    public let individualPrice:     Decimal
    public let totalPrice:          Decimal
    public let discountAllocations: [DiscountAllocationViewModel]
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required public init(from model: ModelType) {
        self.model               = model
        self.cursor              = model.cursor
        
        self.variantID           = model.node.variant!.id.rawValue
        self.title               = model.node.title
        self.quantity            = Int(model.node.quantity)
        self.individualPrice     = model.node.variant!.price.amount
        self.totalPrice          = self.individualPrice * Decimal(self.quantity)
        self.discountAllocations = model.node.discountAllocations.viewModels
    }
}

extension Storefront.CheckoutLineItemEdge: ViewModeling {
    public typealias ViewModelType = LineItemViewModel
}
