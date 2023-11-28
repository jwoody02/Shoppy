//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Foundation
import Buy

public final class CheckoutViewModel: ViewModel {
    
    public typealias ModelType = Storefront.Checkout
    
    public let model:  ModelType
    
    enum PaymentType: String {
        case applePay   = "apple_pay"
        case creditCard = "credit_card"
    }
    
    public let id:               String
    public let ready:            Bool
    public let requiresShipping: Bool
    public let taxesIncluded:    Bool
    public let shippingAddress:  AddressViewModel?
    public let shippingRate:     ShippingRateViewModel?
    
    public let note:             String?
    public let webURL:           URL
    
    public let giftCards:        [GiftCardViewModel]
    public let lineItems:        [LineItemViewModel]
    public let currencyCode:     String
    public let subtotalPrice:    Decimal
    public let totalTax:         Decimal
    public let totalDuties:      Decimal?
    public let totalPrice:       Decimal
    public let paymentDue:       Decimal
    
    public let shippingDiscountName:   String
    public let totalShippingDiscounts: Decimal
    
    public let lineItemDiscountName:   String
    public let totalLineItemDiscounts: Decimal
    public let totalDiscounts:         Decimal
    
    public let shippingDiscountAllocations: [DiscountAllocationViewModel]
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required public init(from model: ModelType) {
        self.model            = model
        
        self.id               = model.id.rawValue
        self.ready            = model.ready
        self.requiresShipping = model.requiresShipping
        self.taxesIncluded    = model.taxesIncluded
        self.shippingAddress  = model.shippingAddress?.viewModel
        self.shippingRate     = model.shippingLine?.viewModel
        
        self.note             = model.note
        self.webURL           = model.webUrl
        
        self.giftCards        = model.appliedGiftCards.viewModels
        self.lineItems        = model.lineItems.edges.viewModels
        self.currencyCode     = model.currencyCode.rawValue
        self.subtotalPrice    = model.subtotalPrice.amount
        self.totalTax         = model.totalTax.amount
        self.totalDuties      = model.totalDuties?.amount
        self.totalPrice       = model.totalPrice.amount
        self.paymentDue       = model.paymentDue.amount
        
        self.shippingDiscountAllocations = model.shippingDiscountAllocations.viewModels

        self.shippingDiscountName   = self.shippingDiscountAllocations.aggregateName
        self.totalShippingDiscounts = self.shippingDiscountAllocations.totalDiscount
        
        let lineItemAllocations     = self.lineItems.flatMap { $0.discountAllocations }
        self.lineItemDiscountName   = lineItemAllocations.aggregateName
        self.totalLineItemDiscounts = lineItemAllocations.totalDiscount
        
        self.totalDiscounts         = self.totalShippingDiscounts + self.totalLineItemDiscounts
    }
}

extension Storefront.Checkout: ViewModeling {
    public typealias ViewModelType = CheckoutViewModel
}
