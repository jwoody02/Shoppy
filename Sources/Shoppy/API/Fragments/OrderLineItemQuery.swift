//
//  OrderLineItemQuery.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//

import Buy
extension Storefront.OrderLineItemConnectionQuery {
    
    @discardableResult
    func fragmentForStandardLineItem() -> Storefront.OrderLineItemConnectionQuery { return self
        .pageInfo { $0
            .hasNextPage()
        }
        .edges { $0
            .cursor()
            .node { $0
                .title()
                .quantity()
                .variant { $0
                    .id()
                    .title()
                    .price { $0
                        .amount()
                        .currencyCode()
                    }
                }
            }
        }
    }
}
