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
    
    public let handle: String
    public let title:  String
    public let price:  Decimal
    
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
