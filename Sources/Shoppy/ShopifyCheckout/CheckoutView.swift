//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/26/23.
//

import UIKit
import WebKit

protocol CheckoutViewDelegate: AnyObject {
    func checkoutViewDidStartNavigation()
    func checkoutViewDidCompleteCheckout()
    func checkoutViewDidFinishNavigation()
    func checkoutViewDidClickLink(url: URL)
    func checkoutViewDidFailWithError(error: CheckoutError)
}

class CheckoutView: WKWebView {

    private static var cache: CacheEntry?

    static func `for`(checkout url: URL) -> CheckoutView {
        guard checkoutConfiguration.preloading.enabled else {
            CheckoutView.cache = nil
            return CheckoutView()
        }

        let cacheKey = url.absoluteString

        guard let cache = cache, cacheKey == cache.key, !cache.isStale else {
            // debug print
            print("CheckoutView cache miss for \(cacheKey)")
            let view = CheckoutView()
            CheckoutView.cache = CacheEntry(key: cacheKey, view: view)
            return view
        }
        // Debug Print
        print("CheckoutView cache hit for \(cacheKey)")
        return cache.view
    }

    static func invalidate() {
        cache = nil
    }

    // MARK: Properties

    weak var viewDelegate: CheckoutViewDelegate?

    // MARK: Initializers

    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        configuration.applicationNameForUserAgent = CheckoutBridge.applicationName

        super.init(frame: frame, configuration: configuration)

        navigationDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: -

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        configuration.userContentController
            .removeScriptMessageHandler(forName: CheckoutBridge.messageHandler)

        if superview != nil {
            configuration.userContentController
                .add(self, name: CheckoutBridge.messageHandler)
        }
    }

    func load(checkout url: URL) {
        load(URLRequest(url: url))
    }
    
}

extension CheckoutView: WKScriptMessageHandler {
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        do {
            switch try CheckoutBridge.decode(message) {
            case .checkoutComplete:
                CheckoutView.cache = nil
                viewDelegate?.checkoutViewDidCompleteCheckout()
            case .checkoutUnavailable:
                CheckoutView.cache = nil
                viewDelegate?.checkoutViewDidFailWithError(error: .checkoutUnavailable(message: "Checkout unavailable."))
            default:
                ()
            }
        } catch {
            viewDelegate?.checkoutViewDidFailWithError(error: .sdkError(underlying: error))
        }
    }
}

extension CheckoutView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        guard let url = action.request.url else {
            decisionHandler(.allow)
            return
        }

        if isExternalLink(action) || isMailOrTelLink(url) {
            viewDelegate?.checkoutViewDidClickLink(url: url)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let response = navigationResponse.response as? HTTPURLResponse {
            decisionHandler(handleResponse(response))
            return
        }
        decisionHandler(.allow)
    }

    func handleResponse(_ response: HTTPURLResponse) -> WKNavigationResponsePolicy {
        if isCheckout(url: response.url) && response.statusCode >= 400 {
            CheckoutView.cache = nil
            switch response.statusCode {
            case 404, 410:
                viewDelegate?.checkoutViewDidFailWithError(error: .checkoutExpired(message: "Checkout has expired"))
            case 500:
                viewDelegate?.checkoutViewDidFailWithError(error: .checkoutUnavailable(message: "Checkout unavailable due to error"))
            default:
                ()
            }

            return .cancel
        }

        return .allow
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        viewDelegate?.checkoutViewDidStartNavigation()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        viewDelegate?.checkoutViewDidFinishNavigation()
        // JavaScript to remove the specified selectors
        let js = """
        var removeSelectors = ['#checkpoint > footer', '#checkpoint > header', '#checkpoint > div.header-bar'];
        removeSelectors.forEach(function(selector) {
            var element = document.querySelector(selector);
            if (element) {
                element.parentNode.removeChild(element);
            }
        });
        """

        // Execute the JavaScript
        webView.evaluateJavaScript(js) { _, error in
            if let error = error {
                print("Error removing elements: \(error.localizedDescription)")
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        CheckoutView.cache = nil
        viewDelegate?.checkoutViewDidFailWithError(error: .sdkError(underlying: error))
    }

    private func isExternalLink(_ action: WKNavigationAction) -> Bool {
        return action.navigationType == .linkActivated && action.targetFrame == nil
    }

    private func isMailOrTelLink(_ url: URL) -> Bool {
        return ["mailto", "tel"].contains(url.scheme)
    }

    private func isCheckout(url: URL?) -> Bool {
        return self.url == url
    }
}

extension CheckoutView {
    fileprivate struct CacheEntry {
        let key: String

        let view: CheckoutView

        private let timestamp = Date()

        private let timeout = TimeInterval(60 * 5)

        var isStale: Bool {
            abs(timestamp.timeIntervalSinceNow) >= timeout
        }
    }
}
