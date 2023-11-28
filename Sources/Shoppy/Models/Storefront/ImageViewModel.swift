//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Foundation
import Buy

public final class ImageViewModel: ViewModel {
    
    public typealias ModelType = Storefront.ImageEdge
    
    public let model:    ModelType
    let cursor:   String
    
    let url:      URL
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required public init(from model: ModelType) {
        self.model    = model
        self.cursor   = model.cursor
        
        self.url      = model.node.url
    }
}

extension Storefront.ImageEdge: ViewModeling {
    public typealias ViewModelType = ImageViewModel
}
