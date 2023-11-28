//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Buy

public final class ManualCodeViewModel: DiscountApplication, ViewModel {
    
    public typealias ModelType = Storefront.ManualDiscountApplication
    
    public let model: ModelType
    let name:  String
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required public init(from model: ModelType) {
        self.model = model
        self.name  = model.title
    }
}

extension Storefront.ManualDiscountApplication: ViewModeling {
    public typealias ViewModelType = ManualCodeViewModel
}
