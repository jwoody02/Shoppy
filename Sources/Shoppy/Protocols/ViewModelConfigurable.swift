//
//  ViewModelConfigurable.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//

import Foundation

public protocol ViewModelConfigurable {
    
    associatedtype ViewModelType
    
    var viewModel: ViewModelType? { get }
    
    func configureFrom(_ viewModel: ViewModelType)
}
