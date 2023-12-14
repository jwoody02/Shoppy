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
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        let backIcon = UIImage(systemName: "arrow.backward")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 10, weight: .bold))
            .withTintColor(.darkGray, renderingMode: .alwaysOriginal)
        button.setImage(backIcon, for: .normal)
        button.addTarget(self, action: #selector(back), for: .touchUpInside)
        
        // Set background color and circular shape
        button.backgroundColor = .lightGray.withAlphaComponent(0.3)
        button.layer.cornerRadius = 17.5  // Assuming a width and height of 50, adjust as necessary
        button.clipsToBounds = true  // Ensures the button is clipped to the rounded corners
        
        return button
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
        
        // Set up and add the back button to the view
        view.addSubview(backButton)
                backButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            backButton.widthAnchor.constraint(equalToConstant: 35),
            backButton.heightAnchor.constraint(equalToConstant: 35)
        ])
        
        NSLayoutConstraint.activate([
            checkoutView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 10),  // Position under the backButton with 10 points of spacing
            checkoutView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            checkoutView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            checkoutView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Create and configure the label
        let titleLabel = UILabel()
        titleLabel.text = "Checkout"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Add the label to the view
        view.addSubview(titleLabel)

        // Set up constraints for the label
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 17),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            // ... other constraints as needed ...
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

    func checkoutViewDidStartNavigation() {
        if initialNavigation {
            spinner.startAnimating()
        }
    }

    func checkoutViewDidFinishNavigation() {
        spinner.stopAnimating()
        initialNavigation = false
        UIView.animate(withDuration: UINavigationController.hideShowBarDuration) { [weak checkoutView] in
            checkoutView?.alpha = 1
        }
    }

    func checkoutViewDidCompleteCheckout() {
        ConfettiCannon.fire(in: view)
        CheckoutView.invalidate()
        delegate?.checkoutDidComplete()
    }

    func checkoutViewDidFailWithError(error: CheckoutError) {
        CheckoutView.invalidate()
        delegate?.checkoutDidFail(error: error)
    }

    func checkoutViewDidClickLink(url: URL) {
        delegate?.checkoutDidClickLink(url: url)
    }
}
