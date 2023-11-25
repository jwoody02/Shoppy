//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Buy

final class ManualCodeViewModel: DiscountApplication, ViewModel {
    
    typealias ModelType = Storefront.ManualDiscountApplication
    
    let model: ModelType
    let name:  String
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required init(from model: ModelType) {
        self.model = model
        self.name  = model.title
    }
}

extension Storefront.ManualDiscountApplication: ViewModeling {
    typealias ViewModelType = ManualCodeViewModel
}
