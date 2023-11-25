//
//  Discount.swift
//
//
//  Created by Jordan Wood on 11/25/23.
//


import Buy
extension Storefront.DiscountApplicationQuery {
    
    @discardableResult
    func fragmentForDiscountApplication() -> Storefront.DiscountApplicationQuery { return self
        .onDiscountCodeApplication { $0
            .applicable()
            .code()
        }
        .onManualDiscountApplication { $0
            .title()
        }
        .onScriptDiscountApplication { $0
            .title()
        }
    }
}

extension Storefront.DiscountAllocationQuery {
    
    @discardableResult
    func fragmentForDiscountAllocation() -> Storefront.DiscountAllocationQuery { return self
        .allocatedAmount { $0
            .amount()
            .currencyCode()
        }
        .discountApplication { $0
            .fragmentForDiscountApplication()
        }
    }
}
