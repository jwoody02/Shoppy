//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/26/23.
//

import UIKit
import WebKit

@available(iOS 13.0, *)
public class CheckoutViewController: UIViewController, UIAdaptivePresentationControllerDelegate {

    // MARK: Properties

    public weak var delegate: CheckoutDelegate?

    private let checkoutView: CheckoutView

    private lazy var spinner: SpinnerView = {
        let spinner = SpinnerView(frame: .zero)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()

    private var initialNavigation: Bool = true

    private let checkoutURL: URL

    private lazy var closeBarButtonItem: UIBarButtonItem = {
        switch checkoutConfiguration.colorScheme {
        case .web:
            let closeIcon = UIImage(systemName: "xmark")?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 14, weight: .regular))
                .withTintColor(.white, renderingMode: .alwaysOriginal)
            return UIBarButtonItem(image: closeIcon, style: .plain, target: self, action: #selector(close))
        default:
            return UIBarButtonItem(
                barButtonSystemItem: .close, target: self, action: #selector(close)
            )
        }
    }()
    


    // MARK: Initializers

    public init(checkoutURL url: URL, delegate: CheckoutDelegate? = nil) {
        self.checkoutURL = url
        self.delegate = delegate

        let checkoutView = CheckoutView.for(checkout: url)
        checkoutView.translatesAutoresizingMaskIntoConstraints = false
        self.checkoutView = checkoutView

        super.init(nibName: nil, bundle: nil)

        title = "Checkout"
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.rightBarButtonItem = closeBarButtonItem

        checkoutView.viewDelegate = self
    }
    
    

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: UIViewController Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white


        view.addSubview(checkoutView)
        

        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        view.bringSubviewToFront(spinner)

        loadCheckout()
        
        NSLayoutConstraint.activate([
            checkoutView.topAnchor.constraint(equalTo: view.topAnchor),  // Position under the backButton with 10 points of spacing
            checkoutView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            checkoutView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            checkoutView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
    }
    
    @objc func back() {
        didCancel()
        navigationController?.popViewController(animated: true)
    }


    private func loadCheckout() {
        if checkoutView.url == nil {
            checkoutView.alpha = 0
            initialNavigation = true
            checkoutView.load(checkout: checkoutURL)
        } else if checkoutView.isLoading && initialNavigation {
            checkoutView.alpha = 0
            spinner.startAnimating()
        }
    }

    @IBAction internal func close() {
        didCancel()
    }

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        didCancel()
    }

    private func didCancel() {
        delegate?.checkoutDidCancel()
    }
}

@available(iOS 13.0, *)
extension CheckoutViewController: CheckoutViewDelegate {

    public func checkoutViewDidStartNavigation() {
        if initialNavigation {
            spinner.startAnimating()
        }
    }

    public func checkoutViewDidFinishNavigation() {
        spinner.stopAnimating()
        initialNavigation = false
        UIView.animate(withDuration: UINavigationController.hideShowBarDuration) { [weak checkoutView] in
            checkoutView?.alpha = 1
        }
    }

    public func checkoutViewDidCompleteCheckout() {
        ConfettiCannon.fire(in: view)
        CheckoutView.invalidate()
        delegate?.checkoutDidComplete()
    }

    public func checkoutViewDidFailWithError(error: CheckoutError) {
        CheckoutView.invalidate()
        delegate?.checkoutDidFail(error: error)
    }

    public func checkoutViewDidClickLink(url: URL) {
        delegate?.checkoutDidClickLink(url: url)
    }
}
