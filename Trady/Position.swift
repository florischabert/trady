//
//  Position.swift
//  Trady
//
//  Created by Floris Chabert on 2/15/16.
//  Copyright © 2016 Floris Chabert. All rights reserved.
//

import UIKit

enum Category: String {
    case Equity = "Equities", Fund = "Funds", Bond = "Bonds", Option = "Options", Cash = "Cash"
    static let allValues = [Equity, Fund, Bond, Option, Cash]
    static let names = [Equity.rawValue, Fund.rawValue, Bond.rawValue, Option.rawValue, Cash.rawValue]
    static let colors = [Equity.color, Fund.color, Bond.color, Option.color, Cash.color]

    var color: UIColor {
        switch (self) {
        case .Equity: return UIColor(red: CGFloat(0.0/255), green: CGFloat(178.0/255), blue: CGFloat(220.0/255), alpha: 1)
        case .Fund: return UIColor(red: CGFloat(255.0/255), green: CGFloat(47.0/255), blue: CGFloat(115.0/255), alpha: 1)
        case .Bond: return UIColor(red: CGFloat(150.0/255), green: CGFloat(140.0/255), blue: CGFloat(138.0/255), alpha: 1)
        case .Option: return UIColor(red: CGFloat(255.0/255), green: CGFloat(148.0/255), blue: CGFloat(0.0/255), alpha: 1)
        default: return UIColor(red: CGFloat(77.0/255), green: CGFloat(195.0/255), blue: CGFloat(33.0/255), alpha: 1)
        }
    }
}

class Position: NSObject, NSCoding {
    var symbol: String
    var descr: String = "-"
    var category: Category

    var price: Double
    var quantity: Double

    var change: Double?
    var cap: String?
    var pe: Double?

    init(_ symbol: String, category: Category, price: Double, quantity: Double, descr: String? = nil) {
        self.symbol = symbol
        self.category = category
        self.price = price
        self.quantity = quantity

        if let descr = descr {
            self.descr = descr
        }

        if category == .Cash {
            self.descr = "Available Cash"
        }

    }

    required convenience init(coder decoder: NSCoder) {
        let symbol = decoder.decodeObjectForKey("symbol") as! String
        let category = Category.allValues[decoder.decodeObjectForKey("category") as! Int]
        let price = decoder.decodeObjectForKey("price") as! Double
        let quantity = decoder.decodeObjectForKey("quantity") as! Double
        let descr = decoder.decodeObjectForKey("descr") as! String

        self.init(symbol, category: category, price: price, quantity: quantity, descr: descr)
    }

    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(symbol, forKey: "symbol")
        coder.encodeObject(Category.allValues.indexOf(category)!, forKey: "category")
        coder.encodeObject(price, forKey: "price")
        coder.encodeObject(quantity, forKey: "quantity")
        coder.encodeObject(descr, forKey: "descr")
    }
}