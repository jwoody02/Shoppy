//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/26/23.
//


import UIKit

@available(iOS 13.0, *)
class SpinnerView: UIView {
    private lazy var imageView: UIImageView = {
        let view = UIImageView(image: UIImage(
            named: "spinner", in: .main, with: nil
        ))
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let animationKey = "SpinnerView.rotation"

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(imageView)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 64),
            heightAnchor.constraint(equalToConstant: 64),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        imageView.tintColor = checkoutConfiguration.spinnerColor

        isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimating() {
        isHidden = false

        let rotation = CABasicAnimation(
            keyPath: "transform.rotation"
        )
        rotation.fromValue = 0
        rotation.toValue = Double.pi * 2
        rotation.duration = 0.5
        rotation.repeatCount = .greatestFiniteMagnitude

        layer.add(rotation, forKey: animationKey)
    }

    func stopAnimating() {
        isHidden = true

        layer.removeAnimation(forKey: animationKey)
    }
}
