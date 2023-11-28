//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//

import Foundation

import Buy

public final class ScriptCodeViewModel: DiscountApplication, ViewModel {
    
    public typealias ModelType = Storefront.ScriptDiscountApplication
    
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

extension Storefront.ScriptDiscountApplication: ViewModeling {
    public typealias ViewModelType = ScriptCodeViewModel
}
