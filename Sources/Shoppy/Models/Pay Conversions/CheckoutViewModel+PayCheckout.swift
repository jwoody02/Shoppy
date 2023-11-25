//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Pay

extension CheckoutViewModel {

    var payCheckout: PayCheckout {
        
        let payItems = self.lineItems.map { item in
            PayLineItem(price: item.individualPrice, quantity: item.quantity)
        }
        
        return PayCheckout(
            id:               self.id,
            lineItems:        payItems,
            giftCards:        self.giftCards.map { $0.payGiftCard },
            discount:         self.totalLineItemDiscounts > 0 ? PayDiscount(code: self.lineItemDiscountName, amount: self.totalLineItemDiscounts) : nil,
            shippingDiscount: self.totalShippingDiscounts > 0 ? PayDiscount(code: self.shippingDiscountName, amount: self.totalShippingDiscounts) : nil,
            shippingAddress:  self.shippingAddress?.payAddress,
            shippingRate:     self.shippingRate?.payShippingRate,
            currencyCode:     self.currencyCode,
            totalDuties:      self.totalDuties,
            subtotalPrice:    self.subtotalPrice,
            needsShipping:    self.requiresShipping,
            totalTax:         self.totalTax,
            paymentDue:       self.paymentDue
        )
    }
}
