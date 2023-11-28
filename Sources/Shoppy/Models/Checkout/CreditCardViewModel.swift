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
    
    public let firstName:    String?
    public let lastName:     String?
    
    public let firstDigits:  String?
    public let lastDigits:   String?
    public let maskedDigits: String?
    
    public let expMonth:     Int?
    public let expYear:      Int?
    public let brand:        String?
    
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
