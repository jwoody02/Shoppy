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
    static let cartItemsDidChange = Notification.Name("CartController.itemsDidChange")
    static let cartStateDidChange = Notification.Name("CartController.stateDidChange")
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
        case idle, updating, creatingCheckout
    }

    public private(set) var state: CartState = .idle {
        didSet { NotificationCenter.default.post(name: .cartStateDidChange, object: self) }
    }
    
    private var checkoutUrl: URL?
    private var checkoutId: String? {
        didSet { saveCheckoutInfo() }
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
        // Determine modifications in the cart
        let modificationsArray = determineModifications()

        // Debugging output
        debugPrintModifications(modificationsArray)

        // Persist current state
        previousItems = items
        flushCartToDisk()
        NotificationCenter.default.post(name: .cartItemsDidChange, object: self)

        // Update or create checkout based on the current state
        if let checkoutId = self.checkoutId, !checkoutId.isEmpty {
            updateExistingCheckout(with: checkoutId, modifications: modificationsArray)
        } else {
            createNewCheckout(with: modificationsArray)
        }
    }

    // MARK: - Checkout Operations
    private func updateExistingCheckout(with checkoutId: String, modifications: [CartItem]) {
        Client.shared?.updateCartLineItems(id: checkoutId, with: modifications) { [weak self] id, url in
            guard let self = self else { return }
            if let id = id, let url = url {
                self.checkoutUrl = url
                self.checkoutId = id
                if #available(iOS 14.0, *) {
                    os_log(.info, "Updated cart with id '\(id)' and checkout url '\(url.absoluteString)', saving to disk.")
                } else {
                    // Fallback on earlier versions
                    print("Updated cart with id '\(id)' and checkout url '\(url.absoluteString)', saving to disk.")
                }
                self.saveCheckoutInfo()
            } else {
                os_log(.fault, "Shoppy Error: Could not update cart")
            }
            self.state = .idle
        }
    }

    private func createNewCheckout(with modifications: [CartItem]) {
        self.state = .creatingCheckout
        var buyerIdentity: Storefront.CartBuyerIdentityInput? = nil
        if let authToken = AccountManager.shared.currentAuthToken(), authToken != "" {
            buyerIdentity = .create(customerAccessToken: .value(authToken))
            if #available(iOS 14.0, *) {
                os_log(.debug, "Associating cart with customer \(authToken)")
            } else {
                // Fallback on earlier versions
                print("Associating cart with customer \(authToken)")
            }
        }
        
        Client.shared?.createCart(with: modifications, buyer: buyerIdentity) { [weak self] id, url in
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
                self.saveCheckoutInfo()
            } else {
                os_log(.fault, "Shoppy Error: Could not create cart")
            }
            self.state = .idle
        }
    }

    // Helper method to determine modifications in the cart
    private func determineModifications() -> [CartItem] {
        var modificationsArray: [CartItem] = []

        // Check for changed or new items
        for item in self.items {
            if let previousItem = self.previousItems.first(where: { $0.variant.id == item.variant.id }) {
                if previousItem.quantity != item.quantity {
                    modificationsArray.append(item) // changed quantity
                }
            } else {
                modificationsArray.append(item) // new item
            }
        }

        // Check for removed items
        for previousItem in self.previousItems {
            if !self.items.contains(where: { $0.variant.id == previousItem.variant.id }) {
                let removedItem = previousItem
                removedItem.quantity = 0
                modificationsArray.append(removedItem)
            }
        }

        return modificationsArray
    }

    // Helper method for debugging
    private func debugPrintModifications(_ modifications: [CartItem]) {
        let debugString = modifications.map { "\($0.variant.id):\($0.quantity)" }.joined(separator: ", ")
        if #available(iOS 14.0, *) {
            os_log(.debug, "Submitting modifications array: \(debugString)")
        } else {
            print("Submitting modifications array: \(debugString)")
        }
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
            os_log("Cart data loaded from disk.")
        } catch {
            os_log("Failed to load cart data: %@", type: .error, error.localizedDescription)
        }
    }



    private func saveCheckoutInfo() {
        ioQueue.async {
            do {
                let checkoutInfo = CheckoutInfo(url: self.checkoutUrl, id: self.checkoutId)
                let data = try JSONEncoder().encode(checkoutInfo)
                let checkoutInfoURL = self.cartFileURL.deletingLastPathComponent().appendingPathComponent("checkoutInfo.json")
                try data.write(to: checkoutInfoURL, options: .atomic)
                os_log("Checkout information saved.")
            } catch {
                os_log("Failed to save checkout information: %@", type: .error, error.localizedDescription)
            }
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
