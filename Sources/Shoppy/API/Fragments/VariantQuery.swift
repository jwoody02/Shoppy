//
//  VariantQuery.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//

import Buy

extension Storefront.ProductVariantConnectionQuery {
    
    @discardableResult
    func fragmentForStandardVariant() -> Storefront.ProductVariantConnectionQuery { return self
        .pageInfo { $0
            .hasNextPage()
        }
        .edges { $0
            .cursor()
            .node { $0
                .id()
                .title()
                .price { $0
                    .amount()
                    .currencyCode()
                }
                .compareAtPrice { $0
                    .amount()
                    .currencyCode()
                }
                .availableForSale()
                .currentlyNotInStock()
                .image { $0
                    .url()
                }
                .selectedOptions { $0
                    .name()
                    .value()
                }
            }
        }
    }
}
