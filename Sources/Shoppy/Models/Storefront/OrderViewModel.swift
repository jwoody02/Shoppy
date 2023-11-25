//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Foundation
import Buy

final class OrderViewModel: ViewModel {
    
    typealias ModelType = Storefront.OrderEdge
    
    let model:                  ModelType
    let cursor:                 String
    
    let id:                     String
    let number:                 Int
    let email:                  String?
    let currentTotalDuties:     Decimal?
    let originalTotalDuties:    Decimal?
    let totalPrice:             Decimal
    
    // ----------------------------------
    //  MARK: - Init -
    //
    required init(from model: ModelType) {
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
    typealias ViewModelType = OrderViewModel
}