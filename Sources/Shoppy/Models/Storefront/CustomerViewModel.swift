//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Foundation
import Buy

final class CustomerViewModel: ViewModel {
    
    typealias ModelType = Storefront.Customer
    
    let model:       ModelType
    
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
    required init(from model: ModelType) {
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
    typealias ViewModelType = CustomerViewModel
}
