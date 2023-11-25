//
//  ViewModeling.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//

import Foundation

protocol ViewModeling {
    
    associatedtype ViewModelType: ViewModel
    
    var viewModel: ViewModelType { get }
}

extension ViewModeling where ViewModelType.ModelType == Self {
    
    var viewModel: ViewModelType {
        return ViewModelType(from: self)
    }
}

extension Array where Element: ViewModeling {
    
    var viewModels: [Element.ViewModelType] {
        return self.map { $0.viewModel }
    }
}
