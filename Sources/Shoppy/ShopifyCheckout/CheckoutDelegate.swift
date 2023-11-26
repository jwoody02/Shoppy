//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/26/23.
//


import Foundation
import UIKit

/// A delegate protocol for managing checkout lifecycle events.
public protocol CheckoutDelegate: AnyObject {
    /// Tells the delegate that the checkout successfully completed.
    func checkoutDidComplete()

    /// Tells the delegate that the checkout was cancelled by the buyer.
    func checkoutDidCancel()

    /// Tells the delegate that the checkout encoutered one or more errors.
    func checkoutDidFail(error: CheckoutError)

    /// Tells te delegate that the buyer clicked a link
    /// This includes email address or telephone number via `mailto:` or `tel:` or `http` links directed outside the application.
    func checkoutDidClickLink(url: URL)
}

extension CheckoutDelegate {
    public func checkoutDidClickLink(url: URL) {
        handleUrl(url)
    }

    private func handleUrl(_ url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
