//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Foundation
import Buy

public final class OrderViewModel: ViewModel {
    
    public typealias ModelType = Storefront.OrderEdge
    
    public let model:                  ModelType
    public let cursor:                 String
    
    public let id:                     String
    public let number:                 Int
    public let email:                  String?
    public let currentTotalDuties:     Decimal?
    public let originalTotalDuties:    Decimal?
    public let totalPrice:             Decimal
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required public init(from model: ModelType) {
        self.model               = model
        self.cursor              = model.cursor
        
        self.id                  = model.node.id.rawValue
        self.number              = Int(model.node.orderNumber)
        self.email               = model.node.email
        self.currentTotalDuties  = model.node.currentTotalDuties?.amount
        self.originalTotalDuties = model.node.originalTotalDuties?.amount
        self.totalPrice          = model.node.totalPrice.amount
    }
}

extension Storefront.OrderEdge: ViewModeling {
    public typealias ViewModelType = OrderViewModel
}
