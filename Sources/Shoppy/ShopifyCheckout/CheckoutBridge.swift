//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/26/23.
//


import WebKit

enum CheckoutBridge {
    static let schemaVersion = "5.1"

    static let messageHandler = "mobileCheckoutSdk"

    static var applicationName: String {
        let theme = checkoutConfiguration.colorScheme.rawValue
        return "ShopifyCheckoutSDK/\(version) (\(schemaVersion);\(theme))"
    }

    static func decode(_ message: WKScriptMessage) throws -> WebEvent {
        guard let body = message.body as? String, let data = body.data(using: .utf8) else {
            throw Error.invalidBridgeEvent()
        }

        do {
            return try JSONDecoder().decode(WebEvent.self, from: data)
        } catch {
            throw Error.invalidBridgeEvent(error)
        }
    }
}

extension CheckoutBridge {
    enum Error: Swift.Error {
        case invalidBridgeEvent(Swift.Error? = nil)
    }
}

extension CheckoutBridge {
    enum WebEvent: Decodable {
        case checkoutComplete
        case checkoutCanceled
        case checkoutExpired
        case checkoutUnavailable
        case unsupported(String)

        enum CodingKeys: String, CodingKey {
            case name
            case body
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            let name = try container.decode(String.self, forKey: .name)

            switch name {
            case "completed":
                self = .checkoutComplete
            case "close":
                self = .checkoutCanceled
            case "error":
                // needs to support .checkoutUnavailable by parsing error payload on body
                self = .checkoutExpired
            default:
                self = .unsupported(name)
            }
        }
    }
}
