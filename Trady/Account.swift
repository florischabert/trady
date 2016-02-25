//
//  Account.swift
//  Trady
//
//  Created by Floris Chabert on 2/5/16.
//  Copyright © 2016 Floris Chabert. All rights reserved.
//

import Foundation

class Account {
    var name: String
    var id: UInt
    var value: Double = 0

    var positions: [Position] = []

    init(name: String, id: UInt, value: Double?) {
        self.name = name
        self.id = id

        if let value = value {
            self.value = value
        }
    }

    func positionsForCategory(category: Category) -> [Position] {
        var positionList: [Position] = []

        for position in positions {
            if position.category == category {
                positionList += [position]
            }
        }

        return positionList
    }

    var total: Double {
        var sum: Double = 0

        for position in positions {
            sum +=  position.price * Double(position.amount)
        }

        return sum
    }

}