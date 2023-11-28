//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Foundation
import Buy

public final class ShippingRateViewModel: ViewModel {
    
    public typealias ModelType = Storefront.ShippingRate
    
    public let model:  ModelType
    
    let handle: String
    let title:  String
    let price:  Decimal
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required public init(from model: ModelType) {
        self.model  = model
        
        self.handle = model.handle
        self.title  = model.title
        self.price  = model.price.amount
    }
}

extension Storefront.ShippingRate: ViewModeling {
    public typealias ViewModelType = ShippingRateViewModel
}
