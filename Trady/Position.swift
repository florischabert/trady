//
//  Position.swift
//  Trady
//
//  Created by Floris Chabert on 2/15/16.
//  Copyright © 2016 Floris Chabert. All rights reserved.
//

import UIKit

class Position: NSObject, NSCoding {
    enum Category: String {
        case Equity = "Equity", Fund = "Fund", Bond = "Bond", Option = "Option"
    }

    var symbol: String
    var descr: String = "-"
    var category: Category

    var price: Double
    var quantity: Double

    init(_ symbol: String, category: Category, price: Double, quantity: Double, descr: String? = nil) {
        self.symbol = symbol
        self.category = category
        self.price = price
        self.quantity = quantity

        if let descr = descr {
            self.descr = descr
        }

    }

    required convenience init(coder decoder: NSCoder) {
        let symbol = decoder.decodeObjectForKey("symbol") as! String
        let category = decoder.decodeObjectForKey("category") as! String
        let price = decoder.decodeObjectForKey("price") as! Double
        let quantity = decoder.decodeObjectForKey("quantity") as! Double
        let descr = decoder.decodeObjectForKey("descr") as! String

        self.init(symbol, category: Category(rawValue: category)!, price: price, quantity: quantity, descr: descr)
    }

    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(symbol, forKey: "symbol")
        coder.encodeObject(category.rawValue, forKey: "category")
        coder.encodeObject(price, forKey: "price")
        coder.encodeObject(quantity, forKey: "quantity")
        coder.encodeObject(descr, forKey: "descr")
    }
}