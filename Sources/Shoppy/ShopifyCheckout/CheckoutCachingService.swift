//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/26/23.
//

import Foundation
class CheckoutCachingService {
    private static let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    
    static func downloadAndCacheCheckoutLink(url: URL) {
        let cacheKey = url.absoluteString
        let cacheDirectory = cacheDirectory.appendingPathComponent(cacheKey)
        
        // Check if the checkout link is already cached
        if FileManager.default.fileExists(atPath: cacheDirectory.path) {
            print("Checkout link already cached")
            return
        }
        
        // Download the checkout link
        guard let data = try? Data(contentsOf: url) else {
            print("Failed to download checkout link")
            return
        }
        
        // Cache the checkout link
        do {
            try data.write(to: cacheDirectory)
            print("Checkout link cached successfully")
        } catch {
            print("Failed to cache checkout link: \(error)")
        }
    }
    
    static func getCheckoutLinkFromCache(url: URL) -> Data? {
        let cacheKey = url.absoluteString
        let cacheDirectory = cacheDirectory.appendingPathComponent(cacheKey)
        
        // Check if the checkout link is cached
        guard FileManager.default.fileExists(atPath: cacheDirectory.path) else {
            print("Checkout link not found in cache")
            return nil
        }
        
        // Retrieve the checkout link from cache
        guard let data = try? Data(contentsOf: cacheDirectory) else {
            print("Failed to retrieve checkout link from cache")
            return nil
        }
        
        print("Checkout link retrieved from cache")
        return data
    }
}
