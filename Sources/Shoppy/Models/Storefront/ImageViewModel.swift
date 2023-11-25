//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Foundation
import Buy

final class ImageViewModel: ViewModel {
    
    typealias ModelType = Storefront.ImageEdge
    
    let model:    ModelType
    let cursor:   String
    
    let url:      URL
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required init(from model: ModelType) {
        self.model    = model
        self.cursor   = model.cursor
        
        self.url      = model.node.url
    }
}

extension Storefront.ImageEdge: ViewModeling {
    typealias ViewModelType = ImageViewModel
}
