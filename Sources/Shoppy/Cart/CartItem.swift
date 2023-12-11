//
//  CartItem.swift
//
//
//  Created by Jordan Wood on 11/25/23.
//


import Foundation

public final class CartItem: Equatable, Hashable, Serializable {
    
    private struct Key {
        static let product  = "product"
        static let quantity = "quantity"
        static let variant  = "variant"
    }
    
    let product: ProductViewModel
    let variant: VariantViewModel
    
    var quantity: Int
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required public init(product: ProductViewModel, variant: VariantViewModel, quantity: Int = 1) {
        self.product  = product
        self.variant  = variant
        self.quantity = quantity
    }
    
    // ----------------------------------
    //  MARK: - Serializable -
    //
    public static func deserialize(from representation: SerializedRepresentation) -> Self? {
        guard let product = ProductViewModel.deserialize(from: representation[Key.product] as! SerializedRepresentation) else {
            return nil
        }
        
        guard let variant = VariantViewModel.deserialize(from: representation[Key.variant] as! SerializedRepresentation) else {
            return nil
        }
        
        guard let quantity = representation[Key.quantity] as? Int else {
            return nil
        }
        
        return self.init(
            product:  product,
            variant:  variant,
            quantity: quantity
        )
    }
    
    public func serialize() -> SerializedRepresentation {
        return [
            Key.quantity : self.quantity,
            Key.product  : self.product.serialize(),
            Key.variant  : self.variant.serialize(),
        ]
    }
}

// ----------------------------------
//  MARK: - Hashable -
//
extension CartItem {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.variant.id)
    }
}

// ----------------------------------
//  MARK: - Equatable -
//
extension CartItem {
    
    public static func ==(lhs: CartItem, rhs: CartItem) -> Bool {
        return lhs.variant.id == rhs.variant.id && lhs.product.id == rhs.product.id
    }
}
