//
//  Client.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//

import Foundation
import Buy
import Pay
import os.log

public struct ClientConfig {
    public var shopDomain: String
    public var apiKey: String
    public var merchantID: String
    public var locale: Locale

    public init(shopDomain: String, apiKey: String, merchantID: String, locale: Locale) {
        self.shopDomain = shopDomain
        self.apiKey = apiKey
        self.merchantID = merchantID
        self.locale = locale
    }
}


public final class Client {
    /// New Initializable Shared Client
    /// Usage:
    ///
    ///     Client.shared = Client(config:
    ///         ClientConfig(shopDomain: "graphql.myshopify.com",
    ///                      apiKey: "8e2fef6daed4b93cf4e731f580799dd1",
    ///                      merchantID: "merchant.com.your.id",
    ///                      locale: Locale(identifier: "en-US"))
    ///     )
    ///
    ///


    public static var shared: Client?

    private let client: Graph.Client
    public var config: ClientConfig
    
    
    // ----------------------------------
    //  MARK: - Init -
    //
    public init(config: ClientConfig) {
        self.config = config
        self.client = Graph.Client(shopDomain: config.shopDomain, apiKey: config.apiKey, locale: config.locale)
//        self.client.cachePolicy = .cacheFirst(expireIn: 3600)
    }
    
    public func getClient() -> Graph.Client {
        return self.client
    }
    
    // ----------------------------------
    //  MARK: - Customers -
    //
    @discardableResult
    func login(email: String, password: String, completion: @escaping (String?, Date?) -> Void) -> Task {
        
        let mutation = ClientQuery.mutationForLogin(email: email, password: password)
        let task     = self.client.mutateGraphWith(mutation) { (mutation, error) in
            error.debugPrint()
            
            if let container = mutation?.customerAccessTokenCreate?.customerAccessToken {
                completion(container.accessToken, container.expiresAt)
            } else {
                let errors = mutation?.customerAccessTokenCreate?.customerUserErrors ?? []
                
                if #available(iOS 14.0, *) {
                    os_log(.fault, "Failed to login: \(errors)")
                } else {
                    print("Failed to login customer: \(errors)")
                }
                completion(nil, nil)
            }
        }
        
        task.resume()
        return task
    }
    
    @discardableResult
    func logout(accessToken: String, completion: @escaping (Bool) -> Void) -> Task {
        
        let mutation = ClientQuery.mutationForLogout(accessToken: accessToken)
        let task     = self.client.mutateGraphWith(mutation) { (mutation, error) in
            error.debugPrint()
            
            if let deletedToken = mutation?.customerAccessTokenDelete?.deletedAccessToken {
                completion(deletedToken == accessToken)
            } else {
                let errors = mutation?.customerAccessTokenDelete?.userErrors ?? []
                if #available(iOS 14.0, *) {
                    os_log(.fault, "Failed to logout: \(errors)")
                } else {
                    print("Failed to logout customer: \(errors)")
                }
                completion(false)
            }
        }
        
        task.resume()
        return task
    }
    
    @discardableResult
    func fetchCustomerAndOrders(limit: Int = 25, after cursor: String? = nil, accessToken: String, completion: @escaping ((customer: CustomerViewModel, orders: PageableArray<OrderViewModel>)?) -> Void) -> Task {
        
        let query = ClientQuery.queryForCustomer(limit: limit, after: cursor, accessToken: accessToken)
        let task  = self.client.queryGraphWith(query) { (query, error) in
            error.debugPrint()
            
            if let customer = query?.customer {
                let viewModel   = customer.viewModel
                let collections = PageableArray(
                    with:     customer.orders.edges,
                    pageInfo: customer.orders.pageInfo
                )
                completion((viewModel, collections))
            } else {
                if #available(iOS 14.0, *) {
                    os_log(.fault, "Failed to load customer and orders: \(String(describing: error))")
                } else {
                    print("Failed to load customer and orders: \(String(describing: error))")
                }
                completion(nil)
            }
        }
        
        task.resume()
        return task
    }
    
    // ----------------------------------
    //  MARK: - Shop -
    //
    @discardableResult
    func fetchShopName(completion: @escaping (String?) -> Void) -> Task {
        
        let query = ClientQuery.queryForShopName()
        let task  = self.client.queryGraphWith(query) { (query, error) in
            error.debugPrint()
            
            if let query = query {
                completion(query.shop.name)
            } else {
                if #available(iOS 14.0, *) {
                    os_log(.fault, "Failed to fetch shop name: \(String(describing: error))")
                } else {
                    print("Failed to fetch shop name: \(String(describing: error))")
                }
                completion(nil)
            }
        }
        
        task.resume()
        return task
    }
    
    @discardableResult
    func fetchShopURL(completion: @escaping (URL?) -> Void) -> Task {
        
        let query = ClientQuery.queryForShopURL()
        let task  = self.client.queryGraphWith(query) { (query, error) in
            error.debugPrint()
            
            if let query = query {
                completion(query.shop.primaryDomain.url)
            } else {
                if #available(iOS 14.0, *) {
                    os_log(.fault, "Failed to fetch shop url: \(String(describing: error))")
                } else {
                    print("Failed to fetch shop url: \(String(describing: error))")
                }
                completion(nil)
            }
        }
        
        task.resume()
        return task
    }
    
    // ----------------------------------
    //  MARK: - Collections -
    //
    @discardableResult
    func fetchCollections(limit: Int = 25, after cursor: String? = nil, productLimit: Int = 25, productCursor: String? = nil, completion: @escaping (PageableArray<CollectionViewModel>?) -> Void) -> Task {
        
        let query = ClientQuery.queryForCollections(limit: limit, after: cursor, productLimit: productLimit, productCursor: productCursor)
        let task  = self.client.queryGraphWith(query) { (query, error) in
            error.debugPrint()
            
            if let query = query {
                let collections = PageableArray(
                    with:     query.collections.edges,
                    pageInfo: query.collections.pageInfo
                )
                completion(collections)
            } else {
                if #available(iOS 14.0, *) {
                    os_log(.fault, "Failed to load collections: \(String(describing: error))")
                } else {
                    print("Failed to load collections: \(String(describing: error))")
                }
                completion(nil)
            }
        }
        
        task.resume()
        return task
    }
    
    // ----------------------------------
    //  MARK: - Products -
    //
    @discardableResult
    func fetchProducts(in collection: CollectionViewModel, limit: Int = 25, after cursor: String? = nil, filters: [Storefront.ProductFilter] = [], completion: @escaping (PageableArray<ProductViewModel>?) -> Void) -> Task {
        
        let query = ClientQuery.queryForProducts(in: collection, limit: limit, after: cursor, filters: filters)
        let task  = self.client.queryGraphWith(query) { (query, error) in
            error.debugPrint()
            
            if let query = query,
                let collection = query.node as? Storefront.Collection {
                
                let products = PageableArray(
                    with:     collection.products.edges,
                    pageInfo: collection.products.pageInfo
                )
                completion(products)
                
            } else {
                if #available(iOS 14.0, *) {
                    os_log(.fault, "Failed to load products in collection (\(collection.model.node.id.rawValue)): \(String(describing: error))")
                } else {
                    print("Failed to load products in collection (\(collection.model.node.id.rawValue)): \(String(describing: error))")
                }
                completion(nil)
            }
        }
        
        task.resume()
        return task
    }
    @discardableResult
    func fetchProductVariant(id: GraphQL.ID, completion: @escaping (Result<Storefront.ProductVariant, Error>) -> Void) -> Task {

        let query = ClientQuery.queryForProductVariant(withId: id)
        let task = self.client.queryGraphWith(query) { (query, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let query = query,
                  let node = query.node as? Storefront.ProductVariant else {
                if #available(iOS 14.0, *) {
                    os_log(.fault, "Failed to fetch product variant \(id)")
                } else {
                    print("Failed to fetch product variant.")
                }
                completion(.failure(CustomError("Failed to fetch product variant.")))
                return
            }

            completion(.success(node))
        }

        task.resume()
        return task
    }
    
    // ----------------------------------
    //  MARK: - Discounts -
    //
    @discardableResult
    func applyDiscount(_ discountCode: String, to checkoutID: String, completion: @escaping (CheckoutViewModel?) -> Void) -> Task {
        let mutation = ClientQuery.mutationForApplyingDiscount(discountCode, to: checkoutID)
        let task     = self.client.mutateGraphWith(mutation) { response, error in
            error.debugPrint()
            
            completion(response?.checkoutDiscountCodeApplyV2?.checkout?.viewModel)
        }
        
        task.resume()
        return task
    }
    
    // ----------------------------------
    //  MARK: - Gift Cards -
    //
    @discardableResult
    func applyGiftCard(_ giftCardCode: String, to checkoutID: String, completion: @escaping (CheckoutViewModel?) -> Void) -> Task {
        let mutation = ClientQuery.mutationForApplyingGiftCard(giftCardCode, to: checkoutID)
        let task     = self.client.mutateGraphWith(mutation) { response, error in
            error.debugPrint()
            
            completion(response?.checkoutGiftCardsAppend?.checkout?.viewModel)
        }
        
        task.resume()
        return task
    }
    
    // ----------------------------------
    //  MARK: - Checkout -
    //
    @discardableResult
    func createCheckout(with cartItems: [CartItem], completion: @escaping (CheckoutViewModel?) -> Void) -> Task {
        let mutation = ClientQuery.mutationForCreateCheckout(with: cartItems)
        let task     = self.client.mutateGraphWith(mutation) { response, error in
            error.debugPrint()
            
            completion(response?.checkoutCreate?.checkout?.viewModel)
        }
        
        task.resume()
        return task
    }
    
    @discardableResult
    func updateCheckout(_ id: String, updatingPartialShippingAddress address: PayPostalAddress, completion: @escaping (CheckoutViewModel?) -> Void) -> Task {
        let mutation = ClientQuery.mutationForUpdateCheckout(id, updatingPartialShippingAddress: address)
        let task     = self.client.mutateGraphWith(mutation) { response, error in
            error.debugPrint()
            
            if let checkout = response?.checkoutShippingAddressUpdateV2?.checkout,
                let _ = checkout.shippingAddress {
                completion(checkout.viewModel)
            } else {
                completion(nil)
            }
        }
        
        task.resume()
        return task
    }
    
    @discardableResult
    func updateCheckout(_ id: String, updatingCompleteShippingAddress address: PayAddress, completion: @escaping (CheckoutViewModel?) -> Void) -> Task {
        let mutation = ClientQuery.mutationForUpdateCheckout(id, updatingCompleteShippingAddress: address)
        let task     = self.client.mutateGraphWith(mutation) { response, error in
            error.debugPrint()
            
            if let checkout = response?.checkoutShippingAddressUpdateV2?.checkout,
                let _ = checkout.shippingAddress {
                completion(checkout.viewModel)
            } else {
                completion(nil)
            }
        }
        
        task.resume()
        return task
    }
    
    @discardableResult
    func updateCheckout(_ id: String, updatingShippingRate shippingRate: PayShippingRate, completion: @escaping (CheckoutViewModel?) -> Void) -> Task {
        let mutation = ClientQuery.mutationForUpdateCheckout(id, updatingShippingRate: shippingRate)
        let task     = self.client.mutateGraphWith(mutation) { response, error in
            error.debugPrint()
            
            if let checkout = response?.checkoutShippingLineUpdate?.checkout,
                let _ = checkout.shippingLine {
                completion(checkout.viewModel)
            } else {
                completion(nil)
            }
        }
        
        task.resume()
        return task
    }
    
    @discardableResult
    func createCart(with cartItems: [CartItem], buyer identity: Storefront.CartBuyerIdentityInput?, completion: @escaping (String?, URL?) -> Void) -> Task {
        let mutation = ClientQuery.mutationForCreateCart(with: cartItems, buyer: identity)
        let task     = self.client.mutateGraphWith(mutation) { response, error in
            error.debugPrint()
            
            if let checkoutUrl = response?.cartCreate?.cart?.checkoutUrl,
               let checkoutId = response?.cartCreate?.cart?.id {
                completion(checkoutId.rawValue, checkoutUrl)
            } else {
                completion(nil, nil)
            }
        }
        
        task.resume()
        return task
    }
    
    @discardableResult
    func updateCartLineItems(id: String, with cartItems: [CartItem], completion: @escaping (String?, URL?) -> Void) -> Task {
        let mutation = ClientQuery.mutationForCartUpdateLineItems(cartid: id, items: cartItems)
        let task     = self.client.mutateGraphWith(mutation) { response, error in
            error.debugPrint()
            
            if let checkoutUrl = response?.cartCreate?.cart?.checkoutUrl,
               let checkoutId = response?.cartCreate?.cart?.id {
                completion(checkoutId.rawValue, checkoutUrl)
            } else {
                completion(nil, nil)
            }
        }
        
        task.resume()
        return task
    }
    
    @discardableResult
    func pollForReadyCheckout(_ id: String, completion: @escaping (CheckoutViewModel?) -> Void) -> Task {

        let retry = Graph.RetryHandler<Storefront.QueryRoot>(endurance: .finite(30)) { response, error -> Bool in
            error.debugPrint()
            return (response?.node as? Storefront.Checkout)?.ready ?? false == false
        }
        
        let query = ClientQuery.queryForCheckout(id)
        let task  = client.queryGraphWith(query, cachePolicy: .networkOnly, retryHandler: retry) { response, error in
            error.debugPrint()
            
            if let checkout = response?.node as? Storefront.Checkout {
                completion(checkout.viewModel)
            } else {
                completion(nil)
            }
        }
        
        task.resume()
        return task
    }
    
    @discardableResult
    func updateCheckout(_ id: String, updatingEmail email: String, completion: @escaping (CheckoutViewModel?) -> Void) -> Task {
        let mutation = ClientQuery.mutationForUpdateCheckout(id, updatingEmail: email)
        let task     = self.client.mutateGraphWith(mutation) { response, error in
            error.debugPrint()
            
            if let checkout = response?.checkoutEmailUpdateV2?.checkout,
                let _ = checkout.email {
                completion(checkout.viewModel)
            } else {
                completion(nil)
            }
        }
        
        task.resume()
        return task
    }
    
    @discardableResult
    func updateCheckout(_ id: String, associatingCustomer accessToken: String, completion: @escaping (CheckoutViewModel?) -> Void) -> Task {
        
        let mutation = ClientQuery.mutationForUpdateCheckout(id, associatingCustomer: accessToken)
        let task     = self.client.mutateGraphWith(mutation) { (mutation, error) in
            error.debugPrint()
            
            if let checkout = mutation?.checkoutCustomerAssociateV2?.checkout {
                completion(checkout.viewModel)
            } else {
                completion(nil)
            }
        }
        
        task.resume()
        return task
    }
    
    @discardableResult
    func fetchShippingRatesForCheckout(_ id: String, completion: @escaping ((checkout: CheckoutViewModel, rates: [ShippingRateViewModel])?) -> Void) -> Task {
        
        let retry = Graph.RetryHandler<Storefront.QueryRoot>(endurance: .finite(30)) { response, error -> Bool in
            error.debugPrint()
            
            if let checkout = response?.node as? Storefront.Checkout {
                return checkout.availableShippingRates?.ready ?? false == false || checkout.ready == false
            } else {
                return false
            }
        }
        
        let query = ClientQuery.queryShippingRatesForCheckout(id)
        let task  = self.client.queryGraphWith(query, cachePolicy: .networkOnly, retryHandler: retry) { response, error in
            error.debugPrint()
            
            if let response = response,
                let checkout = response.node as? Storefront.Checkout {
                completion((checkout.viewModel, checkout.availableShippingRates!.shippingRates!.viewModels))
            } else {
                completion(nil)
            }
        }
        
        task.resume()
        return task
    }
    
    func completeCheckout(_ checkout: PayCheckout, billingAddress: PayAddress, applePayToken token: String, idempotencyToken: String, completion: @escaping (PaymentViewModel?) -> Void) {
        
        let mutation = ClientQuery.mutationForCompleteCheckoutUsingApplePay(checkout, billingAddress: billingAddress, token: token, idempotencyToken: idempotencyToken)
        let task     = self.client.mutateGraphWith(mutation) { response, error in
            error.debugPrint()
            
            if let payment = response?.checkoutCompleteWithTokenizedPaymentV3?.payment {
                
                print("Payment created, fetching status...")
                self.fetchCompletedPayment(payment.id.rawValue) { paymentViewModel in
                    completion(paymentViewModel)
                }
                
            } else {
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    func fetchCompletedPayment(_ id: String, completion: @escaping (PaymentViewModel?) -> Void) {
        
        let retry = Graph.RetryHandler<Storefront.QueryRoot>(endurance: .finite(30)) { response, error -> Bool in
            error.debugPrint()
            
            if let payment = response?.node as? Storefront.Payment {
                print("Payment not ready yet, retrying...")
                return !payment.ready
            } else {
                return false
            }
        }
        
        let query = ClientQuery.queryForPayment(id)
        let task  = self.client.queryGraphWith(query, retryHandler: retry) { query, error in
            
            if let payment = query?.node as? Storefront.Payment {
                print("Payment error: \(payment.errorMessage ?? "none")")
                completion(payment.viewModel)
            } else {
                completion(nil)
            }
        }
        
        task.resume()
    }
}

// ----------------------------------
//  MARK: - GraphError -
//
extension Optional where Wrapped == Graph.QueryError {
    
    func debugPrint() {
        switch self {
        case .some(let value):
            print("Graph.QueryError: \(value)")
        case .none:
            break
        }
    }
}

struct CustomError: Error {
    var message: String

    init(_ message: String) {
        self.message = message
    }
}
