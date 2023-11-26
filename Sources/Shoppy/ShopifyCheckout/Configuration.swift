//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/26/23.
//

import UIKit

public struct Configuration {
    /// Determines the color scheme used when checkout is presented.
    ///
    /// By default, the color scheme is determined based on the current
    /// `UITraitCollection.userInterfaceStyle`. To force a
    /// particular idiomatic color scheme, use the corresponding `.light`
    /// or `.dark` values.
    ///
    /// Alternatively you can use `.web` to match the look and feel of what your
    /// buyers will see when performing a checkout via a desktop or mobile browser.
    public var colorScheme = ColorScheme.automatic

    public var confetti = Configuration.Confetti()

    public var preloading = Configuration.Preloading()

    public var spinnerColor: UIColor = UIColor(red: 0.09, green: 0.45, blue: 0.69, alpha: 1.00)

}

extension Configuration {
    public enum ColorScheme: String, CaseIterable {
        /// Uses a light, idiomatic color scheme.
        case light = "light"
        /// Uses a dark, idiomatic color scheme.
        case dark = "dark"
        /// Infers either `.light` or `.dark` based on the current `UIUserInterfaceStyle`.
        case automatic = "automatic"
        /// The color scheme presented to buyers using a desktop or mobile browser.
        case web = "web_default"
    }
}

extension Configuration {
    public struct Confetti {
        public var enabled: Bool = true

        public var particles = [UIImage]()
    }
}

extension Configuration {
    public struct Preloading {
        public var enabled: Bool = true
    }
}
