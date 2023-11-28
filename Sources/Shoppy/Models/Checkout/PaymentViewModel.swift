//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Foundation
import Buy

public final class PaymentViewModel: ViewModel {
    
    public typealias ModelType = Storefront.Payment
    
    public let model:  ModelType
    
    let id:         String
    let isReady:    Bool
    let isTest:     Bool
    let checkout:   CheckoutViewModel
    let creditCard: CreditCardViewModel?
    let amount:     Decimal
    let error:      String?
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required public init(from model: ModelType) {
        self.model      = model
        
        self.id         = model.id.rawValue
        self.checkout   = model.checkout.viewModel
        self.creditCard = model.creditCard?.viewModel
        self.amount     = model.amount.amount
        self.isTest     = model.test
        self.isReady    = model.ready
        self.error      = model.errorMessage
    }
}

extension Storefront.Payment: ViewModeling {
    public typealias ViewModelType = PaymentViewModel
}
