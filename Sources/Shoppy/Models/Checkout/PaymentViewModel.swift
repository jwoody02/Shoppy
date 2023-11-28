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
    
    public let id:         String
    public let isReady:    Bool
    public let isTest:     Bool
    public let checkout:   CheckoutViewModel
    public let creditCard: CreditCardViewModel?
    public let amount:     Decimal
    public let error:      String?
    
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
