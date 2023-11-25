//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Foundation
import Buy

final class ShippingRateViewModel: ViewModel {
    
    typealias ModelType = Storefront.ShippingRate
    
    let model:  ModelType
    
    let handle: String
    let title:  String
    let price:  Decimal
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required init(from model: ModelType) {
        self.model  = model
        
        self.handle = model.handle
        self.title  = model.title
        self.price  = model.price.amount
    }
}

extension Storefront.ShippingRate: ViewModeling {
    typealias ViewModelType = ShippingRateViewModel
}
