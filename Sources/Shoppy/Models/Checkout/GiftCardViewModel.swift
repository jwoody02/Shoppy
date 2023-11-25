//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Foundation
import Buy

final class GiftCardViewModel: ViewModel {
    
    typealias ModelType = Storefront.AppliedGiftCard
    
    let model:  ModelType
    
    let id:             String
    let balance:        Decimal
    let amountUsed:     Decimal
    let lastCharacters: String
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required init(from model: ModelType) {
        self.model            = model
        
        self.id             = model.id.rawValue
        self.balance        = model.balance.amount
        self.amountUsed     = model.amountUsed.amount
        self.lastCharacters = model.lastCharacters
    }
}

extension Storefront.AppliedGiftCard: ViewModeling {
    typealias ViewModelType = GiftCardViewModel
}
