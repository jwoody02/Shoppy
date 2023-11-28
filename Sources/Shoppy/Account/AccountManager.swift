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
    private let expiryKey = "ShopifyAuthExpiry"
    private let userDefaults = UserDefaults.standard

    var isLoggedIn: Bool {
        return authToken != nil && !isTokenExpired
    }

    private var authToken: String? {
        get {
            return userDefaults.string(forKey: tokenKey)
        }
        set {
            userDefaults.set(newValue, forKey: tokenKey)
            delegate?.accountManagerDidUpdateLoginStatus(self, isLoggedIn: newValue != nil && !isTokenExpired)
        }
    }

    private var authTokenExpiry: Date? {
        get {
            return userDefaults.object(forKey: expiryKey) as? Date
        }
        set {
            userDefaults.set(newValue, forKey: expiryKey)
        }
    }

    private var isTokenExpired: Bool {
        if let expiryDate = authTokenExpiry {
            return Date() >= expiryDate
        }
        return true
    }

    private init() {}

    func login(email: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        Client.shared?.login(email: email, password: password) { [weak self] (token, expiryDate) in
            guard let self = self, let token = token, let expiryDate = expiryDate else {
                completion(false, nil)
                return
            }
            
            self.authToken = token
            self.authTokenExpiry = expiryDate
            completion(true, nil)
        }
    }

    func validateLogin(completion: @escaping (Bool) -> Void) {
        if isLoggedIn {
            completion(true)
        } else {
            logout()
            completion(false)
        }
    }

    func logout() {
        self.authToken = nil
        guard let auth = authToken else { return }
        Client.shared?.logout(accessToken: auth) { success in
            if success {
                print("Successfully logged out")
            } else {
                print("Error logging out")
            }
        }
    }
    
    func currentAuthToken() -> String? {
        return self.authToken
    }
}
