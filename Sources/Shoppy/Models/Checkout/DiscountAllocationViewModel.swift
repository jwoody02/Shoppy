//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Foundation
import Buy

public final class DiscountAllocationViewModel: ViewModel {
    
    public typealias ModelType = Storefront.DiscountAllocation
    
    public let model: ModelType
    
    public let amount:       Decimal
    public let currencyCode: String
    let application:  DiscountApplication
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required public init(from model: ModelType) {
        self.model        = model
        
        self.amount       = model.allocatedAmount.amount
        self.currencyCode = model.allocatedAmount.currencyCode.rawValue
        self.application  = model.discountApplication.resolvedViewModel
    }
}

extension Storefront.DiscountAllocation: ViewModeling {
    public typealias ViewModelType = DiscountAllocationViewModel
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
