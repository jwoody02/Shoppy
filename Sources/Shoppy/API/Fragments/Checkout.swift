//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//

import Buy

extension Storefront.CheckoutQuery {
    
    @discardableResult
    func fragmentForCheckout() -> Storefront.CheckoutQuery { return self
        .id()
        .ready()
        .requiresShipping()
        .taxesIncluded()
        .email()
        
        .discountApplications(first: 250) { $0
            .edges { $0
                .node { $0
                    .fragmentForDiscountApplication()
                }
            }
        }
        
        .shippingDiscountAllocations { $0
            .fragmentForDiscountAllocation()
        }
        
        .appliedGiftCards { $0
            .id()
            .balance { $0
                .amount()
                .currencyCode()
            }
            .amountUsed { $0
                .amount()
                .currencyCode()
            }
            .lastCharacters()
        }
        
        .shippingAddress { $0
            .firstName()
            .lastName()
            .phone()
            .address1()
            .address2()
            .city()
            .country()
            .countryCodeV2()
            .province()
            .provinceCode()
            .zip()
        }
        
        .shippingLine { $0
            .handle()
            .title()
            .price { $0
                .amount()
                .currencyCode()
            }
        }
        
        .note()
        .lineItems(first: 250) { $0
            .edges { $0
                .cursor()
                .node { $0
                    .variant { $0
                        .id()
                        .price { $0
                            .amount()
                            .currencyCode()
                        }
                    }
                    .title()
                    .quantity()
                    .discountAllocations { $0
                        .fragmentForDiscountAllocation()
                    }
                }
            }
        }
        .totalDuties { $0
            .amount()
            .currencyCode()
        }
        .webUrl()
        .currencyCode()
        .subtotalPrice { $0
            .amount()
            .currencyCode()
        }
        .totalTax { $0
            .amount()
            .currencyCode()
        }
        .totalPrice { $0
            .amount()
            .currencyCode()
        }
        .paymentDue { $0
            .amount()
            .currencyCode()
        }
    }
}
