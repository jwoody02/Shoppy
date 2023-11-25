//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Buy

protocol DiscountApplication {
    var name: String { get }
}

extension Buy.DiscountApplication {
    
    var resolvedViewModel: DiscountApplication {
        switch self {
        case let discount as Storefront.DiscountCodeApplication:
            return discount.viewModel
        case let discount as Storefront.ManualDiscountApplication:
            return discount.viewModel
        case let discount as Storefront.ScriptDiscountApplication:
            return discount.viewModel
        default:
            fatalError("Unsupported DiscountApplication type: \(type(of: self))")
        }
    }
}

extension Array where Element == Buy.DiscountApplication {
    
    var viewModels: [DiscountApplication] {
        return self.map { $0.resolvedViewModel }
    }
}

