//
//  ProductConnectionQuery.swift
//
//
//  Created by Jordan Wood on 11/25/23.
//

import Buy

extension Storefront.ProductConnectionQuery {
    
    @discardableResult
    func fragmentForStandardProduct() -> Storefront.ProductConnectionQuery { return self
        .pageInfo { $0
            .hasNextPage()
        }
        .edges { $0
            .cursor()
            .node { $0
                .id()
                .title()
                .availableForSale()
                .descriptionHtml()
                .variants(first: 250) { $0
                    .fragmentForStandardVariant()
                }
                .images(first: 250) { $0
                    .fragmentForStandardProductImage()
                }
            }
        }
    }
}
