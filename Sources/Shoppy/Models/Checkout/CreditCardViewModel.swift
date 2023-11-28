//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Foundation
import Buy

public final class CreditCardViewModel: ViewModel {
    
    public typealias ModelType = Storefront.CreditCard
    
    public let model:  ModelType
    
    let firstName:    String?
    let lastName:     String?
    
    let firstDigits:  String?
    let lastDigits:   String?
    let maskedDigits: String?
    
    let expMonth:     Int?
    let expYear:      Int?
    let brand:        String?
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required public init(from model: ModelType) {
        self.model        = model
        
        self.firstName    = model.firstName
        self.lastName     = model.lastName
        
        self.firstDigits  = model.firstDigits
        self.lastDigits   = model.lastDigits
        self.maskedDigits = model.maskedNumber
        
        self.expMonth     = model.expiryMonth == nil ? nil : Int(model.expiryMonth!)
        self.expYear      = model.expiryYear  == nil ? nil : Int(model.expiryYear!)
        self.brand        = model.brand
    }
}

extension Storefront.CreditCard: ViewModeling {
    public typealias ViewModelType = CreditCardViewModel
}
