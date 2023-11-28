//
//  CartController.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Foundation
import Buy


extension Notification.Name {
    static let CartControllerItemsDidChange = Notification.Name("CartController.ItemsDidChange")
}

class CartController {
    
    static let shared = CartController()
    
    private(set) var items: [CartItem] = []
    
    var subtotal: Decimal {
        return self.items.reduce(0) {
            $0 + $1.variant.price * Decimal($1.quantity)
        }
    }
    
    var itemCount: Int {
        return self.items.reduce(0) {
            $0 + $1.quantity
        }
    }
    
    private let ioQueue    = DispatchQueue(label: "com.storefront.writeQueue")
    private var needsFlush = false
    private var cartURL: URL = {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let documentsURL  = URL(fileURLWithPath: documentsPath)
        let cartURL       = documentsURL.appendingPathComponent("\(Client.shared?.config.shopDomain ?? "").json")
        
        print("Cart URL: \(cartURL)")
        
        return cartURL
    }()
    
    public var checkoutUrl: URL?
    public var checkoutId: String? {
        didSet {
            self.saveCheckoutInfo()
        }
    }
    
    public enum CartState {
        case idle
        case updating
        case creatingCheckout
    }

    public private(set) var state: CartState = .idle {
        didSet {
            notifyCartStateChange()
        }
    }
    
    // ----------------------------------
    //  MARK: - Init -
    //
    private init() {
        self.readCart { items in
            if let items = items {
                self.items = items
                
                self.postItemsChangedNotification()
            }
        }
    }
    
    // ----------------------------------
    //  MARK: - Notifications -
    //
    private func postItemsChangedNotification() {
        let notification = Notification(name: Notification.Name.CartControllerItemsDidChange)
        NotificationQueue.default.enqueue(notification, postingStyle: .asap)
    }
    
    // ----------------------------------
    //  MARK: - IO Management -
    //
    private func setNeedsFlush() {
        if !self.needsFlush {
            self.needsFlush = true
            
            DispatchQueue.main.async(execute: self.flush)
        }
    }
    
    private func flush() {
        let serializedItems = self.items.serialize()
        self.ioQueue.async {
            do {
                let data = try JSONSerialization.data(withJSONObject: serializedItems, options: [])
                try data.write(to: self.cartURL, options: [.atomic])
                
                print("Flushed cart to disk.")
                
            } catch let error {
                print("Failed to flush cart to disk: \(error)")
            }
            
            DispatchQueue.main.async {
                self.needsFlush = false
            }
        }
    }
    
    private func readCart(completion: @escaping ([CartItem]?) -> Void) {
        self.ioQueue.async {
            do {
                let data            = try Data(contentsOf: self.cartURL)
                let serializedItems = try JSONSerialization.jsonObject(with: data, options: [])
                
                let cartItems = [CartItem].deserialize(from: serializedItems as! [SerializedRepresentation])
                DispatchQueue.main.async {
                    completion(cartItems)
                }
                
            } catch let error {
                print("Failed to load cart from disk: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    // ----------------------------------
    //  MARK: - Checkout Info Persistence -
    //
    private func saveCheckoutInfo() {
        self.ioQueue.async {
            do {
                var checkoutInfo = [String: String]()
                if let url = self.checkoutUrl {
                    checkoutInfo["url"] = url.absoluteString
                }
                if let id = self.checkoutId {
                    checkoutInfo["id"] = id
                }
                
                let data = try JSONSerialization.data(withJSONObject: checkoutInfo, options: [])
                let checkoutInfoURL = self.cartURL.deletingLastPathComponent().appendingPathComponent("checkoutInfo.json")
                try data.write(to: checkoutInfoURL, options: [.atomic])

                print("Checkout information saved.")
            } catch let error {
                print("Failed to save checkout information: \(error)")
            }
        }
    }
    
    private func readCheckoutInfo() {
        self.ioQueue.async {
            let checkoutInfoURL = self.cartURL.deletingLastPathComponent().appendingPathComponent("checkoutInfo.json")
            do {
                let data = try Data(contentsOf: checkoutInfoURL)
                if let checkoutInfo = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                    DispatchQueue.main.async {
                        self.checkoutUrl = URL(string: checkoutInfo["url"] ?? "")
                        self.checkoutId = checkoutInfo["id"]
                    }
                }
            } catch let error {
                print("Failed to load checkout information: \(error)")
            }
        }
    }

    // ----------------------------------
    //  MARK: - State Changes -
    //
    private func itemsChanged() {
        self.state = .updating
        self.setNeedsFlush()
        self.postItemsChangedNotification()

        if let checkoutId = self.checkoutId {
            // Update existing checkout
            Client.shared?.updateCartLineItems(id: checkoutId, with: self.items) { [weak self] id, url in
                if let id = id, let _ = url {
                    self?.checkoutUrl = url
                    self?.checkoutId = id
                    self?.saveCheckoutInfo()
                    print("Updated cart with id '\(id)', saving to disk.")
                } else {
                    print("Shoppy Error: Could not update cart")
                }
                self?.state = .idle
            }
        } else {
            self.state = .creatingCheckout
            var buyerIdentity: Storefront.CartBuyerIdentityInput? = nil
            if let authToken = AccountManager.shared.currentAuthToken() {
                buyerIdentity = .create(customerAccessToken: .value(authToken))
                print("Associating cart with customer \(authToken)")
            }
            
            // Create new checkout
            Client.shared?.createCart(with: self.items, buyer: buyerIdentity) { [weak self] id, url in
                if let id = id, let url = url {
                    self?.checkoutUrl = url
                    self?.checkoutId = id
                    self?.saveCheckoutInfo()
                    print("Created cart with id '\(id)', saving to disk.")
                } else {
                    print("Shoppy Error: Could not create cart")
                }
                self?.state = .idle
            }
        }
    }
    
    // ----------------------------------
    //  MARK: - Item Management -
    //
    func updateQuantity(_ quantity: Int, at index: Int) -> Bool {
        let existingItem = self.items[index]
        
        if existingItem.quantity != quantity {
            existingItem.quantity = quantity
            
            self.itemsChanged()
            return true
        }
        return false
    }
    
    func incrementAt(_ index: Int) {
        let existingItem = self.items[index]
        existingItem.quantity += 1
        
        self.itemsChanged()
    }
    
    func decrementAt(_ index: Int) {
        let existingItem = self.items[index]
        existingItem.quantity -= 1
        
        self.itemsChanged()
    }
    
    func add(_ cartItem: CartItem) {
        if let index = self.items.firstIndex(of: cartItem) {
            self.items[index].quantity += 1
        } else {
            self.items.append(cartItem)
        }
        
        self.itemsChanged()
    }
    
    func removeAllQuantitiesFor(_ cartItem: CartItem) {
        if let index = self.items.firstIndex(of: cartItem) {
            self.removeAllQuantities(at: index)
        }
    }
    
    func removeAllQuantities(at index: Int) {
        self.items.remove(at: index)
        self.itemsChanged()
    }
    
    private func notifyCartStateChange() {
        NotificationCenter.default.post(name: .CartControllerStateDidChange, object: self)
    }
}

extension Notification.Name {
    static let CartControllerStateDidChange = Notification.Name("CartControllerStateDidChange")
}
