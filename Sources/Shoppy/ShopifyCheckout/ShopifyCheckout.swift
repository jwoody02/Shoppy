//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/26/23.
//


import UIKit

/// The version of the `ShopifyCheckout` library.
public let version = "0.1.0"

/// The configuration options for the `ShopifyCheckout` library.
public var checkoutConfiguration = Configuration() {
    didSet {
        CheckoutView.invalidate()
    }
}

/// A convienence function for configuring the `ShopifyCheckout` library.
public func configure(_ block: (inout Configuration) -> Void) {
    block(&checkoutConfiguration)
}

/// Preloads the checkout for faster presentation.
public func preload(checkout url: URL) {
    guard checkoutConfiguration.preloading.enabled else { return }
    CheckoutView.for(checkout: url).load(checkout: url)
}

/// Presents the checkout from a given `UIViewController`.
@available(iOS 13.0, *)
public func present(checkout url: URL, from: UIViewController, delegate: CheckoutDelegate? = nil) {
    let rootViewController = CheckoutViewController(checkoutURL: url, delegate: delegate)
    let viewController = UINavigationController(rootViewController: rootViewController)
    viewController.presentationController?.delegate = rootViewController
    from.present(viewController, animated: true)
}
/// Push checkout instead of present
@available(iOS 13.0, *)
public func push(checkout url: URL, from: UIViewController, delegate: CheckoutDelegate? = nil) {
    let checkoutViewController = CheckoutViewController(checkoutURL: url, delegate: delegate)
    if let navigationController = from.navigationController {
        navigationController.pushViewController(checkoutViewController, animated: true)
    } else {
        // Fallback: present modally if there's no navigation controller
        let navigationController = UINavigationController(rootViewController: checkoutViewController)
        from.present(navigationController, animated: true)
    }
}

