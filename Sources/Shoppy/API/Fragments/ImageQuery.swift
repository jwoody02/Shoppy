//
//  ImageQuery.swift
//
//
//  Created by Jordan Wood on 11/25/23.
//

import Buy

extension Storefront.ImageConnectionQuery {
    
    @discardableResult
    func fragmentForStandardProductImage() -> Storefront.ImageConnectionQuery { return self
        .pageInfo { $0
            .hasNextPage()
        }
        .edges { $0
            .cursor()
            .node { $0
                .url()
            }
        }
    }
}
