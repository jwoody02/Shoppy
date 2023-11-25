//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//

import Pay

extension AddressViewModel {
        
    var payAddress: PayAddress {
        
        return PayAddress(
            addressLine1: self.address1,
            addressLine2: self.address2,
            city:         self.city,
            country:      self.country,
            province:     self.province,
            zip:          self.zip,
            firstName:    self.firstName,
            lastName:     self.lastName,
            phone:        self.phone,
            email:        nil
        )
    }
}
