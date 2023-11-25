//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Foundation
import Buy

final class DiscountAllocationViewModel: ViewModel {
    
    typealias ModelType = Storefront.DiscountAllocation
    
    let model: ModelType
    
    let amount:       Decimal
    let currencyCode: String
    let application:  DiscountApplication
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required init(from model: ModelType) {
        self.model        = model
        
        self.amount       = model.allocatedAmount.amount
        self.currencyCode = model.allocatedAmount.currencyCode.rawValue
        self.application  = model.discountApplication.resolvedViewModel
    }
}

extension Storefront.DiscountAllocation: ViewModeling {
    typealias ViewModelType = DiscountAllocationViewModel
}

extension Array where Element == DiscountAllocationViewModel {
    
    var aggregateName: String {
        return self.map {
            $0.application.name
        }.joined(separator: ", ")
    }
    
    var totalDiscount: Decimal {
        return reduce(0) {
            $0 + $1.amount
        }
    }
}
