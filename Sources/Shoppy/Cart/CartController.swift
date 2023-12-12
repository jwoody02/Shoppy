//
//  CartController.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Foundation
import Buy
import os.log

extension Notification.Name {
    static let CartControllerItemsDidChange = Notification.Name("CartController.ItemsDidChange")
}

public final class CartController {
    
    public static let shared = CartController()
    
    private(set) var items: [CartItem] = []
    private(set) var previousItems: [CartItem] = []
    
    public var subtotal: Decimal {
        return self.items.reduce(0) {
            $0 + $1.variant.price * Decimal($1.quantity)
        }
    }
    
    public var itemCount: Int {
        return self.items.reduce(0) {
            $0 + $1.quantity
        }
    }
    
    private let ioQueue    = DispatchQueue(label: "com.storefront.writeQueue")
    private var needsFlush = false
    private var localCartFile: URL = {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let documentsURL  = URL(fileURLWithPath: documentsPath)
        let cartURL       = documentsURL.appendingPathComponent("\(Client.shared?.config.shopDomain ?? "").json")
        
        if #available(iOS 14.0, *) {
            os_log(.debug, "Cart URL: \(cartURL)")
        } else {
            print("Cart URL: \(cartURL)")
        }
        
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
        self.readCart { items, previousItems in
            if let items = items {
                self.items = items
            }
            if let previousItems = previousItems {
                self.previousItems = previousItems
            }
            self.postItemsChangedNotification()
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
    
    private func ensureCartFileExists() {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: self.localCartFile.path) {
            if #available(iOS 14.0, *) {
                os_log(.info, "Creating cart file at \(self.localCartFile.path)..")
            } else {
                print("Creating cart file..")
            }
            if let jsonData = try? JSONSerialization.data(withJSONObject: [], options: []) {
                fileManager.createFile(atPath: self.localCartFile.path, contents: jsonData, attributes: nil)
            }
        }
    }


    private func flush() {
        let serializedItems = self.items.serialize()
        let serializedPreviousItems = self.previousItems.serialize() // Serialize previousItems
        self.ioQueue.async {
            do {
                self.ensureCartFileExists()
                
                let cartData = ["items": serializedItems, "previousItems": serializedPreviousItems] // Combine items and previousItems
                let data = try JSONSerialization.data(withJSONObject: cartData, options: [])
                try data.write(to: self.localCartFile, options: [.atomic])
                
                if #available(iOS 14.0, *) {
                    os_log(.info, "Flushed cart to disk.")
                } else {
                    print("Flushed cart to disk.")
                }
                
            } catch let error {
                if #available(iOS 14.0, *) {
                    os_log(.fault, "Failed to flush cart to disk: \(error)")
                } else {
                    print("Failed to flush cart to disk: \(error)")
                }
            }
            
            DispatchQueue.main.async {
                self.needsFlush = false
            }
        }
    }

    private func readCart(completion: @escaping ([CartItem]?, [CartItem]?) -> Void) {
        self.ioQueue.async {
            do {
                self.ensureCartFileExists()
                
                let data = try Data(contentsOf: self.localCartFile)
                let cartData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                let cartItems = [CartItem].deserialize(from: cartData?["items"] as? [SerializedRepresentation] ?? [])
                let previousCartItems = [CartItem].deserialize(from: cartData?["previousItems"] as? [SerializedRepresentation] ?? []) // Deserialize previousItems
                DispatchQueue.main.async {
                    completion(cartItems, previousCartItems)
                }
                
            } catch let error {
                if #available(iOS 14.0, *) {
                    os_log(.fault, "Failed to load cart from disk: \(error)")
                } else {
                    print("Failed to load cart from disk: \(error)")
                }
                DispatchQueue.main.async {
                    completion(nil, nil)
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
                let checkoutInfoURL = self.localCartFile.deletingLastPathComponent().appendingPathComponent("checkoutInfo.json")
                try data.write(to: checkoutInfoURL, options: [.atomic])

                if #available(iOS 14.0, *) {
                    os_log(.info, "Checkout information saved.")
                } else {
                    print("Checkout information saved.")
                }
            } catch let error {
                if #available(iOS 14.0, *) {
                    os_log(.fault, "Failed to save checkout information: \(error)")
                } else {
                    print("Failed to save checkout information: \(error)")
                }
            }
        }
    }
    
    private func readCheckoutInfo() {
        self.ioQueue.async {
            let checkoutInfoURL = self.localCartFile.deletingLastPathComponent().appendingPathComponent("checkoutInfo.json")
            do {
                let data = try Data(contentsOf: checkoutInfoURL)
                if let checkoutInfo = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                    DispatchQueue.main.async {
                        self.checkoutUrl = URL(string: checkoutInfo["url"] ?? "")
                        self.checkoutId = checkoutInfo["id"]
                    }
                }
            } catch let error {
                if #available(iOS 14.0, *) {
                    os_log(.fault, "Failed to load checkout information: \(error)")
                } else {
                    print("Failed to load checkout information: \(error)")
                }
            }
        }
    }

    // ----------------------------------
    //  MARK: - State Changes -
    //
    private func itemsChanged() {
        self.state = .updating

        var modificationsArray: [CartItem] = []
        
        // Iterate through current items to detect changes and removals
        for item in self.items {
            if let previousItem = self.previousItems.first(where: { $0.variant.id == item.variant.id }) {
                if previousItem.quantity != item.quantity {
                    modificationsArray.append(item) // changed quantity
                }
            } else {
                modificationsArray.append(item) // new item
            }
        }

        // Detect removed items
        for previousItem in self.previousItems {
            if !self.items.contains(where: { $0.variant.id == previousItem.variant.id }) {
                let removedItem = previousItem
                removedItem.quantity = 0
                modificationsArray.append(removedItem)
            }
        }

        // print out modifications array for debugging, print variant id and quantity
        let debugString = modificationsArray.map { "\($0.quantity) \($0.variant.id)" }.joined(separator: ", ")
        if #available(iOS 14.0, *) {
            os_log(.debug, "Submitting modifications array: \(debugString)")
        } else {
            // Fallback on earlier versions
            print("Submitting modifications array: \(debugString)")
        }

        self.previousItems = self.items
        self.setNeedsFlush()
        self.postItemsChangedNotification()
        
        if let checkoutId = self.checkoutId {
            // Update existing checkout
            Client.shared?.updateCartLineItems(id: checkoutId, with: modificationsArray) { [weak self] id, url in
                if let id = id, let url = url {
                    self?.checkoutUrl = url
                    self?.checkoutId = id
                    if #available(iOS 14.0, *) {
                        os_log(.info, "Updated cart with id '\(id)', saving to disk.")
                    } else {
                        print("Updated cart with id '\(id)', saving to disk.")
                    }
                    self?.saveCheckoutInfo()
                } else {
                    if #available(iOS 14.0, *) {
                        os_log(.fault, "Shoppy Error: Could not update cart")
                    } else {
                        print("Shoppy Error: Could not update cart")
                    }
                }
                self?.state = .idle
            }
        } else {
            self.state = .creatingCheckout
            var buyerIdentity: Storefront.CartBuyerIdentityInput? = nil
            if let authToken = AccountManager.shared.currentAuthToken() {
                buyerIdentity = .create(customerAccessToken: .value(authToken))
                if #available(iOS 14.0, *) {
                    os_log(.debug, "Associating cart with customer \(authToken)")
                } else {
                    print("Associating cart with customer \(authToken)")
                }
            }
            
            // Create new checkout
            Client.shared?.createCart(with: self.items, buyer: buyerIdentity) { [weak self] id, url in
                if let id = id, let url = url {
                    self?.checkoutUrl = url
                    self?.checkoutId = id
                    if #available(iOS 14.0, *) {
                        os_log(.info, "Created cart with id '\(id)', saving to disk.")
                    } else {
                        print("Created cart with id '\(id)', saving to disk.")
                    }
                    self?.saveCheckoutInfo()
                } else {
                    if #available(iOS 14.0, *) {
                        os_log(.fault, "Shoppy Error: Could not create cart")
                    } else {
                        print("Shoppy Error: Could not create cart")
                    }
                }
                self?.state = .idle
            }
        }
    }
    
    // ----------------------------------
    //  MARK: - Item Management -
    //
    public func updateQuantity(_ quantity: Int, at index: Int) -> Bool {
        let existingItem = self.items[index]
        
        if existingItem.quantity != quantity {
            existingItem.quantity = quantity
            
            self.itemsChanged()
            return true
        }
        return false
    }
    
    public func incrementAt(_ index: Int) {
        let existingItem = self.items[index]
        existingItem.quantity += 1
        
        self.itemsChanged()
    }
    
    public func decrementAt(_ index: Int) {
        let existingItem = self.items[index]
        existingItem.quantity -= 1
        
        self.itemsChanged()
    }
    
    public func add(_ cartItem: CartItem) {
        if let index = self.items.firstIndex(of: cartItem) {
            self.items[index].quantity += 1
        } else {
            self.items.append(cartItem)
        }
        
        self.itemsChanged()
    }
    
    public func removeAllQuantitiesFor(_ cartItem: CartItem) {
        if let index = self.items.firstIndex(of: cartItem) {
            self.removeAllQuantities(at: index)
        }
    }
    
    public func removeAllQuantities(at index: Int) {
        self.items.remove(at: index)
        self.itemsChanged()
    }
    
    private func notifyCartStateChange() {
        NotificationCenter.default.post(name: .CartControllerStateDidChange, object: self)
    }
    
    
    public func validateCart(completion: @escaping (Bool) -> Void) {
        guard !self.items.isEmpty else {
            completion(true)
            return
        }

        var isCartValid = true
        let group = DispatchGroup()

        for item in self.items {
            group.enter()
            validateCartItem(item) { isValid in
                if !isValid {
                    isCartValid = false
                    self.removeItem(item)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(isCartValid)
        }
    }

    public func resetEverything() {
        self.items = []
        self.previousItems = []
        self.checkoutUrl = nil
        self.checkoutId = nil
        self.saveCheckoutInfo()
        self.itemsChanged()
        self.resetCartFile()
    }

    private func resetCartFile() {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: self.localCartFile.path) {
            do {
                try fileManager.removeItem(at: self.localCartFile)
                if #available(iOS 14.0, *) {
                    os_log(.info, "Cart file deleted.")
                } else {
                    print("Cart file deleted.")
                }
            } catch let error {
                if #available(iOS 14.0, *) {
                    os_log(.fault, "Failed to delete cart file: \(error)")
                } else {
                    print("Failed to delete cart file: \(error)")
                }
            }
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

    private func removeItem(_ cartItem: CartItem) {
        if let index = self.items.firstIndex(of: cartItem) {
            self.items.remove(at: index)
            self.itemsChanged()
        }
    }
}

public extension Notification.Name {
    static let CartControllerStateDidChange = Notification.Name("CartControllerStateDidChange")
}
