//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/26/23.
//


/// A type representing Shopify Checkout specific errors.
public enum CheckoutError: Swift.Error {
    /// Issued when an internal error within Shopify Checkout SDK
    /// In event of an sdkError you could use the stacktrace to inform you of how to proceed,
    /// if the issue persists, it is recommended to open a bug report in http://github.com/Shopify/mobile-checkout-sdk-ios
    case sdkError(underlying: Swift.Error)

    /// Issued when checkout has encountered a unrecoverable error (for example server side error)
    /// if the issue persists, it is recommended to open a bug report in http://github.com/Shopify/mobile-checkout-sdk-ios
    case checkoutUnavailable(message: String)

    /// Issued when checkout is no longer available and will no longer be available with the checkout url supplied.
    /// This may happen when the user has paused on checkout for a long period (hours) and then attempted to proceed again with the same checkout url
    /// In event of checkoutExpired, a new checkout url will need to be generated
    case checkoutExpired(message: String)
}
