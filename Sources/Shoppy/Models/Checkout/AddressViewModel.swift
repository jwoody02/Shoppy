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
    
    public let firstName:   String?
    public let lastName:    String?
    public let phone:       String?
    
    public let address1:    String?
    public let address2:    String?
    public let city:        String?
    public let country:     String?
    public let countryCode: String?
    public let province:    String?
    public let zip:         String?
    
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
