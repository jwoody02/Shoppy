//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Buy

public final class DiscountCodeViewModel: DiscountApplication, ViewModel {
    
    public typealias ModelType = Storefront.DiscountCodeApplication

    public let model: ModelType
    let name:  String
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required public init(from model: ModelType) {
        self.model = model
        self.name  = model.code
    }
}

extension Storefront.DiscountCodeApplication: ViewModeling {
    public typealias ViewModelType = DiscountCodeViewModel
}
