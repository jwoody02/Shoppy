//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Foundation
import Buy

final class LineItemViewModel: ViewModel {
    
    typealias ModelType = Storefront.CheckoutLineItemEdge
    
    let model:    ModelType
    let cursor:   String
    
    let variantID:           String?
    let title:               String
    let quantity:            Int
    let individualPrice:     Decimal
    let totalPrice:          Decimal
    let discountAllocations: [DiscountAllocationViewModel]
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required init(from model: ModelType) {
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
    typealias ViewModelType = LineItemViewModel
}
