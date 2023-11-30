//
//  CartItemViewModel.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Foundation

public final class CartItemViewModel: ViewModel {
    public typealias ModelType = CartItem
    
    public let model: ModelType
    
    public let imageURL: URL?
    public let title:    String
    public let subtitle: String
    public let price:    String
    public let quantity: Int
    
    var quantityDescription: String {
        return "Quantity: \(model.quantity)"
    }
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required public init(from model: ModelType) {
        self.model = model
        
        self.imageURL = model.product.images.items.first?.url
        self.title    = model.product.title
        self.subtitle = model.variant.title
        self.quantity = model.quantity
        self.price    = Currency.stringFrom(model.variant.price * Decimal(model.quantity))
    }
}

extension CartItem: ViewModeling {
    public typealias ViewModelType = CartItemViewModel
}
