//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/26/23.
//

import Foundation
import os.log
class CheckoutCachingService {
    private static let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    
    static func downloadAndCacheCheckoutLink(url: URL) {
        let cacheKey = url.absoluteString
        let cacheDirectory = cacheDirectory.appendingPathComponent(cacheKey)
        
        // Check if the checkout link is already cached
        if FileManager.default.fileExists(atPath: cacheDirectory.path) {
            if #available(iOS 14.0, *) {
                os_log(.debug, "Checkout link already cached")
            } else {
                print("Checkout link already cached")
            }
            return
        }
        
        // Download the checkout link
        guard let data = try? Data(contentsOf: url) else {
            if #available(iOS 14.0, *) {
                os_log(.error, "Failed to download checkout link from \(url.absoluteString)")
            } else {
                print("Failed to download checkout link")
            }
            return
        }
        
        // Cache the checkout link
        do {
            try data.write(to: cacheDirectory)
            if #available(iOS 14.0, *) {
                os_log(.debug, "Checkout link cached successfully")
            } else {
                print("Checkout link cached successfully")
            }
        } catch {
            if #available(iOS 14.0, *) {
                os_log(.error, "Failed to cache checkout link: \(error)")
            } else {
                print("Failed to cache checkout link: \(error)")
            }
        }
    }
    
    static func getCheckoutLinkFromCache(url: URL) -> Data? {
        let cacheKey = url.absoluteString
        let cacheDirectory = cacheDirectory.appendingPathComponent(cacheKey)
        
        // Check if the checkout link is cached
        guard FileManager.default.fileExists(atPath: cacheDirectory.path) else {
            if #available(iOS 14.0, *) {
                os_log(.error, "Checkout link not found in cache")
            } else {
                print("Checkout link not found in cache")
            }
            return nil
        }
        
        // Retrieve the checkout link from cache
        guard let data = try? Data(contentsOf: cacheDirectory) else {
            print()
            if #available(iOS 14.0, *) {
                os_log(.error, "Failed to retrieve checkout link from cache")
            } else {
                print("Failed to retrieve checkout link from cache")
            }
            return nil
        }
        
        if #available(iOS 14.0, *) {
            os_log(.info, "Checkout link retrieved from cache")
        } else {
            print("Checkout link retrieved from cache")
        }
        return data
    }
}
