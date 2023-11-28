//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Foundation
import Buy

public final class CustomerViewModel: ViewModel {
    
    public typealias ModelType = Storefront.Customer
    
    public let model:       ModelType
    
    let id:          String
    let displayName: String
    let firstName:   String?
    let lastName:    String?
    let phoneNumber: String?
    let email:       String?
    let updatedAt:   Date
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required public init(from model: ModelType) {
        self.model       = model
        
        self.id          = model.id.rawValue
        self.displayName = model.displayName
        self.firstName   = model.firstName
        self.lastName    = model.lastName
        self.phoneNumber = model.phone
        self.email       = model.email
        self.updatedAt   = model.updatedAt
    }
}

extension Storefront.Customer: ViewModeling {
    public typealias ViewModelType = CustomerViewModel
}
