//
//  File.swift
//  
//
//  Created by Jordan Wood on 11/25/23.
//


import Pay

extension GiftCardViewModel {
    
    var payGiftCard: PayGiftCard {
        return PayGiftCard(
            id: self.id,
            balance: self.balance,
            amount: self.amountUsed,
            lastCharacters: self.lastCharacters
        )
    }
}
