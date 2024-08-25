//
//  ClientQuery.swift
//
//
//  Created by Jordan Wood on 11/25/23.
//


import UIKit
import Buy

public final class ClientQuery {

    static let maxImageDimension = Int32(UIScreen.main.bounds.width)
    
    // ----------------------------------
    //  MARK: - Customers -
    //
    static func mutationForLogin(email: String, password: String) -> Storefront.MutationQuery {
        let input = Storefront.CustomerAccessTokenCreateInput(email: email, password: password)
        return Storefront.buildMutation { $0
            .customerAccessTokenCreate(input: input) { $0
                .customerAccessToken { $0
                    .accessToken()
                    .expiresAt()
                }
                .customerUserErrors { $0
                    .code()
                    .field()
                    .message()
                }
            }
        }
    }
    
    static func mutationForLogout(accessToken: String) -> Storefront.MutationQuery {
        return Storefront.buildMutation { $0
            .customerAccessTokenDelete(customerAccessToken: accessToken) { $0
                .deletedAccessToken()
                .userErrors { $0
                    .field()
                    .message()
                }
            }
        }
    }
    
    static func queryForCustomer(limit: Int, after cursor: String? = nil, accessToken: String) -> Storefront.QueryRootQuery {
        return Storefront.buildQuery { $0
            .customer(customerAccessToken: accessToken) { $0
                .id()
                .displayName()
                .email()
                .firstName()
                .lastName()
                .phone()
                .updatedAt()
                .orders(first: Int32(limit), after: cursor) { $0
                    .fragmentForStandardOrder()
                }
            }
        }
    }
    
    // ----------------------------------
    //  MARK: - Shop -
    //
    static func queryForShopName() -> Storefront.QueryRootQuery {
        return Storefront.buildQuery { $0
            .shop { $0
                .name()
            }
        }
    }
    
    static func queryForShopURL() -> Storefront.QueryRootQuery {
        return Storefront.buildQuery { $0
            .shop { $0
                .primaryDomain { $0
                    .url()
                }
            }
        }
    }
    
    // ----------------------------------
    //  MARK: - Storefront -
    //
    static func queryForCollections(limit: Int, after cursor: String? = nil, productLimit: Int = 25, productCursor: String? = nil, searchQuery: String? = nil) -> Storefront.QueryRootQuery {
        return Storefront.buildQuery { $0
            .collections(first: Int32(limit), after: cursor, query: searchQuery) { $0
                .pageInfo { $0
                    .hasNextPage()
                }
                .edges { $0
                    .cursor()
                    .node { $0
                        .id()
                        .title()
                        .descriptionHtml()
                        .image { $0
                            .url()
                        }
                        .products(first: Int32(productLimit), after: productCursor) { $0
                            .fragmentForStandardProduct()
                        }
                    }
                }
            }
        }
    }
    
    static func queryForCollectionWithHandle(handle: String, limit: Int32 = 50, after cursor: String? = nil, filters: [Storefront.ProductFilter] = [], sortKey: Storefront.ProductCollectionSortKeys = .collectionDefault, shouldReverse: Bool? = nil) -> Storefront.QueryRootQuery {
        return Storefront.buildQuery { $0
            .collection(handle: handle) { $0
                .id()
                .title()
                .descriptionHtml()
                .image { $0
                    .url()
                }
                .handle()
                .products(first: limit, after: cursor, reverse: shouldReverse, sortKey: sortKey, filters: filters) { $0
                    .fragmentForStandardProduct()
                }
            }
        }
    }
    
    static func queryForProducts(collectionId collection: GraphQL.ID, limit: Int, after cursor: String? = nil, filters: [Storefront.ProductFilter] = [], sortKey: Storefront.ProductCollectionSortKeys = .collectionDefault, shouldReverse: Bool? = nil) -> Storefront.QueryRootQuery {
        
        return Storefront.buildQuery { $0
            .node(id: collection) { $0
                .onCollection { $0
                    .products(first: Int32(limit), after: cursor, reverse: shouldReverse, sortKey: sortKey, filters: filters) { $0
                        .fragmentForStandardProduct()
                    }
                }
            }
        }
    }
    
    static func queryForProductVariant(withId id: GraphQL.ID) -> Storefront.QueryRootQuery {
        return Storefront.buildQuery { $0
            .node(id: id) { $0
                .onProductVariant { $0
                    .id()
                    .title()
                    .price { $0
                        .amount()
                        .currencyCode()
                    }
                    .availableForSale()
                    .currentlyNotInStock()
                }
            }
        }
    }
    
    // ----------------------------------
    //  MARK: - Cart -
    //
    static func mutationForCreateCart(with cartItems: [CartItem], buyer identity: Storefront.CartBuyerIdentityInput?) -> Storefront.MutationQuery {
        let linesInput: [Storefront.CartLineInput] = cartItems.map {
            .create(
                merchandiseId: GraphQL.ID(rawValue: $0.variant.id),
                quantity: Input(orNull: Int32($0.quantity))
            )
        }
        
        let cartInput: Storefront.CartInput = Storefront.CartInput.create(
            lines: .value(linesInput)
        )
        
        if let identity = identity {
            cartInput.buyerIdentity = .value(identity)
        }
        
        
        return Storefront.buildMutation { $0
            .cartCreate(input: cartInput) { $0
                .cart { $0
                    .id()
                    .checkoutUrl()
                }
                .userErrors { $0
                    .code()
                    .field()
                    .message()
                }
            }
        }
    }
    
    static func mutationForCartAddLineItem(cartid: String, item: CartItem) -> Storefront.MutationQuery {
        let id = GraphQL.ID(rawValue: item.variant.id)
        let quantity = Int32(item.quantity)
        let lineItem = Storefront.CartLineInput.create(merchandiseId: id, quantity: Input(orNull: quantity))
        return Storefront.buildMutation { $0
            .cartLinesAdd(lines: [lineItem], cartId: GraphQL.ID(rawValue: cartid)) { $0
                .cart { $0
                    .id()
                    .checkoutUrl()
                }
                .userErrors { $0
                    .code()
                    .field()
                    .message()
                }
            }
        }
    }
    
    static func mutationForCartRemoveLineItem(cartid: String, item: CartItem) -> Storefront.MutationQuery {
        let id = GraphQL.ID(rawValue: item.variant.id)
        return Storefront.buildMutation { $0
            .cartLinesRemove(cartId: GraphQL.ID(rawValue:cartid), lineIds: [id]) { $0
                .cart { $0
                    .id()
                    .checkoutUrl()
                }
                .userErrors { $0
                    .code()
                    .field()
                    .message()
                }
            }
        }
    }
    
    static func mutationForCartUpdateLineItems(cartid: String, items: [CartItem]) -> Storefront.MutationQuery {
        let lineItems = items.map {
            Storefront.CartLineUpdateInput.create(
                id: GraphQL.ID(rawValue: $0.product.id),
                quantity: Input(orNull: Int32($0.quantity)),
                merchandiseId: .value(GraphQL.ID(rawValue: $0.variant.id))
            )
        }
        
        return Storefront.buildMutation { $0
            .cartLinesUpdate(cartId: GraphQL.ID(rawValue: cartid), lines: lineItems) { $0
                .cart { $0
                    .id()
                    .checkoutUrl()
                }
                .userErrors { $0
                    .code()
                    .field()
                    .message()
                }
            }
        }
    }
}
