//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Foundation
import Buy

public final class GiftCardViewModel: ViewModel {
    
    public typealias ModelType = Storefront.AppliedGiftCard
    
    public let model:  ModelType
    
    public let id:             String
    public let balance:        Decimal
    public let amountUsed:     Decimal
    public let lastCharacters: String
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required public init(from model: ModelType) {
        self.model            = model
        
        self.id             = model.id.rawValue
        self.balance        = model.balance.amount
        self.amountUsed     = model.amountUsed.amount
        self.lastCharacters = model.lastCharacters
    }
}

extension Storefront.AppliedGiftCard: ViewModeling {
    public typealias ViewModelType = GiftCardViewModel
}
