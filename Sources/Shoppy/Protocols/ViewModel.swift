//
//  ViewModel.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//

import Foundation

protocol ViewModel: Serializable {
    
    associatedtype ModelType: Serializable
    
    var model: ModelType { get }
    
    init(from model: ModelType)
}

// ----------------------------------
//  MARK: - Serializable -
//
extension ViewModel {
    
    static func deserialize(from representation: SerializedRepresentation) -> Self? {
        if let model = ModelType.deserialize(from: representation) {
            return Self.init(from: model)
        }
        return nil
    }
    
    func serialize() -> SerializedRepresentation {
        return self.model.serialize()
    }
}
