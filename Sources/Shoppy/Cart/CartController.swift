//
//  CartController.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Foundation
import Buy
import os.log

import Foundation
import Buy
import os.log

extension Notification.Name {
    public static let cartItemsDidChange = Notification.Name("CartController.itemsDidChange")
    public static let cartStateDidChange = Notification.Name("CartController.stateDidChange")
}

public final class CartController {
    
    // MARK: - Singleton Instance
    public static let shared = CartController()

    // MARK: - Properties
    private(set) var items: [CartItem] = []
    private(set) var previousItems: [CartItem] = []
    
    public var subtotal: Decimal {
        items.reduce(0) { $0 + $1.variant.price * Decimal($1.quantity) }
    }
    
    public var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    public enum CartState {
        case readingCart, readCart, idle, updating, creatingCheckout
    }

    public private(set) var state: CartState = .idle {
        didSet { NotificationCenter.default.post(name: .cartStateDidChange, object: self) }
    }
    
    private var checkoutUrl: URL?
    private var checkoutId: String? {
        didSet { flushCartToDisk() }
    }

    // MARK: - File Management
    private let ioQueue = DispatchQueue(label: "com.storefront.cartIOQueue")
    private var needsFlush = false
    private var cartFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("cart-\(Client.shared?.config.shopDomain ?? "default").json")
    }

    // MARK: - Initialization
    private init() {
        loadCart()
    }
    
    // MARK: - Public + Cart Operations
    public func addItem(_ cartItem: CartItem) {
        if let index = items.firstIndex(of: cartItem) {
            items[index].quantity += 1
        } else {
            items.append(cartItem)
        }
        itemsChanged()
    }

    public func updateItemQuantity(at index: Int, to quantity: Int) {
        guard index < items.count else { return }
        items[index].quantity = quantity
        itemsChanged()
    }

    public func removeItem(at index: Int) {
        guard index < items.count else { return }
        items.remove(at: index)
        itemsChanged()
    }

    public func removeAll() {
        items.removeAll()
        itemsChanged()
    }

    public func getItems() -> [CartItem] {
        return items
    }

    public func getCheckoutUrl() -> URL? {
        return checkoutUrl
    }

    public func getCheckoutId() -> String? {
        return checkoutId
    }

    // MARK: - Cart State Handling
    private func itemsChanged() {

        // Persist current state
        previousItems = items
        flushCartToDisk()
        NotificationCenter.default.post(name: .cartItemsDidChange, object: self)
    }

    // MARK: - Checkout Operations
    public func validateCart(completion: @escaping (Bool) -> Void) {
        guard !self.items.isEmpty else {
            completion(true)
            return
        }

        var isCartValid = true
        var modifiedCart = false
        let group = DispatchGroup()

        for item in self.items {
            group.enter()
            validateCartItem(item) { [weak self] isValid in
                if !isValid {
                    isCartValid = false
                    if let index = self?.items.firstIndex(of: item) {
                        self?.removeItem(at: index)
                        modifiedCart = true
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if modifiedCart {
                self.flushCartToDisk()
            }
            completion(isCartValid)
        }
    }
    
    private func validateCartItem(_ cartItem: CartItem, completion: @escaping (Bool) -> Void) {
        Client.shared?.fetchProductVariant(id: GraphQL.ID(rawValue: cartItem.variant.id) ) { result in
            switch result {
            case .success(let variant):
                let isValid = variant.availableForSale && variant.currentlyNotInStock == false
                completion(isValid)
            case .failure(_):
                completion(false)
            }
        }
    }

    public static func generateCartBuyerInputFrom(
        firstName: String = "",
        lastName: String = "",
        email: String = "",
        phone: String = "",
        address1: String = "",
        address2: String = "",
        city: String = "",
        state: String = "",
        zip: String = "",
        country: String = ""
    ) -> Storefront.CartBuyerIdentityInput {
        return Storefront.CartBuyerIdentityInput.create(
            email: .value(email),
            phone: .value(phone),
            deliveryAddressPreferences: .value([Storefront.DeliveryAddressInput.create(
                deliveryAddress: .value(Storefront.MailingAddressInput.create(
                    address1: .value(address1),
                    address2: .value(address2),
                    city: .value(city),
                    company: .value(""),
                    country: .value(country),
                    firstName: .value(firstName),
                    lastName: .value(lastName),
                    phone: .value(phone),
                    province: .value(state),
                    zip: .value(zip)
                )
                )
            )
            ])
        )
    }
    
    public func createNewCheckout(with items: [CartItem], customBuyId: Storefront.CartBuyerIdentityInput? = nil, completion: @escaping (URL?) -> Void) {
        self.state = .creatingCheckout
        var buyerIdentity: Storefront.CartBuyerIdentityInput? = customBuyId
        if let authToken = AccountManager.shared.currentAuthToken(), authToken != "", buyerIdentity == nil {
            buyerIdentity = .create(customerAccessToken: .value(authToken))
            if #available(iOS 14.0, *) {
                os_log(.debug, "Associating cart with customer \(authToken)")
            } else {
                // Fallback on earlier versions
                print("Associating cart with customer \(authToken)")
            }
        }
        
        Client.shared?.createCart(with: items, buyer: buyerIdentity) { [weak self] id, url in
            guard let self = self else { return }
            if let id = id, let url = url {
                self.checkoutUrl = url
                self.checkoutId = id
                if #available(iOS 14.0, *) {
                    os_log(.info, "Created cart with id '\(id)' and checkout url '\(url.absoluteString)', saving to disk.")
                } else {
                    // Fallback on earlier versions
                    print("Created cart with id '\(id)' and checkout url '\(url.absoluteString)', saving to disk.")
                }
                
            } else {
                os_log(.fault, "Shoppy Error: Could not create cart")
            }
            self.state = .idle
            completion(url)
        }
    }
    
    // MARK: - Cart Reset
    public func resetCart() {
        // Clear all items and previous items
        items.removeAll()
        previousItems.removeAll()

        // Reset checkout related properties
        checkoutUrl = nil
        checkoutId = nil

        // Reset cart state
        state = .idle

        // Notify observers that the cart items have changed
        NotificationCenter.default.post(name: .cartItemsDidChange, object: self)

        // Save the reset state to disk
        flushCartToDisk()
    }
    
    // MARK: - IO Operations
    private func flushCartToDisk() {
        needsFlush = true
        ioQueue.async {
            let cartData = CartData(items: self.items, previousItems: self.previousItems, checkoutUrl: self.checkoutUrl, checkoutId: self.checkoutId)
            let serializedData = cartData.serialize()

            do {
                let data = try JSONSerialization.data(withJSONObject: serializedData, options: [])
                try data.write(to: self.cartFileURL, options: .atomic)
                os_log("Cart data saved to disk.")
            } catch {
                os_log("Failed to save cart data: %@", type: .error, error.localizedDescription)
            }
            self.needsFlush = false
        }
    }


    private func loadCart() {
        ioQueue.async {
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: self.cartFileURL.path) {
                os_log("Cart file does not exist. Creating a new one.")
                self.createInitialCartFile()
                self.readCartFile()
            } else {
                self.readCartFile()
            }
        }
    }

    private func createInitialCartFile() {
        let initialCartData = CartData(items: [], previousItems: [], checkoutUrl: nil, checkoutId: nil)
        let serializedData = initialCartData.serialize()

        do {
            let data = try JSONSerialization.data(withJSONObject: serializedData, options: [])
            try data.write(to: self.cartFileURL, options: .atomic)
            os_log("New cart file created.")
        } catch {
            os_log("Failed to create new cart file: %@", type: .error, error.localizedDescription)
        }
    }

    private func readCartFile() {
        state = .readingCart
        do {
            let data = try Data(contentsOf: self.cartFileURL)
            guard let serializedData = try JSONSerialization.jsonObject(with: data, options: []) as? SerializedRepresentation,
                  let cartData = CartData.deserialize(from: serializedData) else {
                os_log("Failed to deserialize cart data")
                return
            }

            self.items = cartData.items
            self.previousItems = cartData.previousItems
            self.checkoutUrl = cartData.checkoutUrl
            self.checkoutId = cartData.checkoutId
            if #available(iOS 14.0, *) {
                os_log(.info, "Cart '\(self.checkoutId ?? "NONE")' loaded from disk with \(self.items.count) items.")
            } else {
                // Fallback on earlier versions
                print("Cart '\(self.checkoutId ?? "NONE")' loaded from disk.")
            }
            state = .readCart
        } catch {
            os_log("Failed to load cart data: %@", type: .error, error.localizedDescription)
        }
    }


}

// MARK: - Cart Data Structure
public struct CartData {
    var items: [CartItem]
    var previousItems: [CartItem]
    var checkoutUrl: URL?
    var checkoutId: String?

    private enum Key {
        static let items = "items"
        static let previousItems = "previousItems"
        static let checkoutUrl = "checkoutUrl"
        static let checkoutId = "checkoutId"
    }

    public func serialize() -> SerializedRepresentation {
        var representation: SerializedRepresentation = [
            Key.items: items.map { $0.serialize() },
            Key.previousItems: previousItems.map { $0.serialize() }
        ]

        if let checkoutUrl = checkoutUrl {
            representation[Key.checkoutUrl] = checkoutUrl.absoluteString
        }

        if let checkoutId = checkoutId {
            representation[Key.checkoutId] = checkoutId
        }

        return representation
    }

    public static func deserialize(from representation: SerializedRepresentation) -> CartData? {
        guard let itemsRepresentation = representation[Key.items] as? [SerializedRepresentation],
              let previousItemsRepresentation = representation[Key.previousItems] as? [SerializedRepresentation] else {
            return nil
        }

        let items = itemsRepresentation.compactMap(CartItem.deserialize)
        let previousItems = previousItemsRepresentation.compactMap(CartItem.deserialize)

        let checkoutUrl = (representation[Key.checkoutUrl] as? String).flatMap(URL.init)
        let checkoutId = representation[Key.checkoutId] as? String

        return CartData(items: items, previousItems: previousItems, checkoutUrl: checkoutUrl, checkoutId: checkoutId)
    }
}

// MARK: - Checkout Info Structure
struct CheckoutInfo: Codable {
    var url: URL?
    var id: String?
}
