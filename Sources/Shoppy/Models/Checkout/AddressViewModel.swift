//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Foundation
import Buy

public final class AddressViewModel: ViewModel {
    
    public typealias ModelType = Storefront.MailingAddress
    
    public let model:  ModelType
    
    let firstName:   String?
    let lastName:    String?
    let phone:       String?
    
    let address1:    String?
    let address2:    String?
    let city:        String?
    let country:     String?
    let countryCode: String?
    let province:    String?
    let zip:         String?
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required public init(from model: ModelType) {
        self.model       = model
        
        self.firstName   = model.firstName
        self.lastName    = model.lastName
        self.phone       = model.phone
        
        self.address1    = model.address1
        self.address2    = model.address2
        self.city        = model.city
        self.country     = model.country
        self.countryCode = model.countryCodeV2?.rawValue
        self.province    = model.province
        self.zip         = model.zip
    }
}

extension Storefront.MailingAddress: ViewModeling {
    public typealias ViewModelType = AddressViewModel
}
