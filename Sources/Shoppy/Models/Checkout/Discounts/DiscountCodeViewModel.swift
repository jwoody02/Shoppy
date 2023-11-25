//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Buy

final class DiscountCodeViewModel: DiscountApplication, ViewModel {
    
    typealias ModelType = Storefront.DiscountCodeApplication

    let model: ModelType
    let name:  String
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required init(from model: ModelType) {
        self.model = model
        self.name  = model.code
    }
}

extension Storefront.DiscountCodeApplication: ViewModeling {
    typealias ViewModelType = DiscountCodeViewModel
}
