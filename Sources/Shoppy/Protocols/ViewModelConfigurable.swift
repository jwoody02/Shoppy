//
//  ViewModelConfigurable.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//

import Foundation

protocol ViewModelConfigurable {
    
    associatedtype ViewModelType
    
    var viewModel: ViewModelType? { get }
    
    func configureFrom(_ viewModel: ViewModelType)
}
