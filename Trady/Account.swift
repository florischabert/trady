//
//  Account.swift
//  Trady
//
//  Created by Floris Chabert on 2/5/16.
//  Copyright © 2016 Floris Chabert. All rights reserved.
//

import Foundation

class Account: NSObject, NSCoding {
    let id: String
    var value: Double
    var cash: Double
    var change: Double?

    var positions: [Position] = []

    init(_ id: String, value: Double, cash: Double) {
        self.id = id
        self.value = value
        self.cash = cash
    }

    required convenience init(coder decoder: NSCoder) {
        let id = decoder.decodeObjectForKey("id") as! String
        let value = decoder.decodeObjectForKey("value") as! Double
        let cash = decoder.decodeObjectForKey("cash") as! Double
        let positions = decoder.decodeObjectForKey("positions") as! [Position]

        self.init(id, value: value, cash: cash)
        self.positions = positions
    }

    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(id, forKey: "id")
        coder.encodeObject(value, forKey: "value")
        coder.encodeObject(cash, forKey: "cash")
        coder.encodeObject(positions, forKey: "positions")
    }

    func save() {
        let defaults = NSUserDefaults.standardUserDefaults()
        let data = NSKeyedArchiver.archivedDataWithRootObject(self) as NSData
        defaults.removeObjectForKey("account")
        defaults.setObject(data, forKey: "account")
        defaults.synchronize()
    }

    func valueForCategory(category: Category) -> Double {
        var value: Double = 0
        for position in positions {
            if category == position.category {
                value += position.price * position.quantity
            }
        }
        return value
    }

}
