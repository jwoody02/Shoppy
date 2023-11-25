//
//  GraphQL+Serializable.swift
//
//
//  Created by Jordan Wood on 11/25/23.
//

import Buy

extension GraphQL.AbstractResponse: Serializable {
    
    static func deserialize(from representation: SerializedRepresentation) -> Self? {
        return try? self.init(fields: representation)
    }
    
    func serialize() -> SerializedRepresentation {
        return self.rawValue
    }
}
