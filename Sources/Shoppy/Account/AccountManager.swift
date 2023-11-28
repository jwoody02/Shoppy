//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/27/23.
//

import Foundation
import Buy

protocol AccountManagerDelegate: AnyObject {
    func accountManagerDidUpdateLoginStatus(_ manager: AccountManager, isLoggedIn: Bool)
}

class AccountManager {

    static let shared = AccountManager()
    weak var delegate: AccountManagerDelegate?

    private let tokenKey = "ShopifyAuthToken"
    private let userDefaults = UserDefaults.standard

    var isLoggedIn: Bool {
        return authToken != nil
    }

    private var authToken: String? {
        get {
            return userDefaults.string(forKey: tokenKey)
        }
        set {
            userDefaults.set(newValue, forKey: tokenKey)
            delegate?.accountManagerDidUpdateLoginStatus(self, isLoggedIn: newValue != nil)
        }
    }

    private init() {}

    func login(email: String, password: String, completion: @escaping (Bool) -> Void) {
        // Login and save data
        Client.shared?.login(email: email, password: password) { [weak self] token in
            guard let self = self, let token = token else {
                completion(false)
                return
            }
            
            self.authToken = token
            completion(true)
        }
    }

    func validateLogin(completion: @escaping (Bool) -> Void) {
        // Implement logic to validate if the current auth token is still valid
        // This might involve making a network request to Shopify to validate the token
        // Placeholder for the actual implementation
        ShopifyClient.shared.validateToken(self.authToken) { isValid in
            completion(isValid)
            if !isValid {
                self.logout()
            }
        }
    }

    func logout() {
        guard let auth = authToken else { return }
        Client.shared?.logout(accessToken: auth) { [weak self] success in
            if success {
                print("Successfully logged out")
                self?.authToken = nil
            } else {
                print("Error logging out")
            }
        }
    }
    
    func currentAuthToken() -> String? {
        return self?.authToken
    }
}
