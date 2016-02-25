//
//  Position.swift
//  Trady
//
//  Created by Floris Chabert on 2/15/16.
//  Copyright © 2016 Floris Chabert. All rights reserved.
//

import UIKit

enum Category: String {
    case Equity = "Equities", ETF = "ETFs", Fund = "Funds", Bond = "Bonds", Cash = "Cash"
    static let allValues = [Equity, ETF, Fund, Bond, Cash]
    static let names = [Equity.rawValue, ETF.rawValue, Fund.rawValue, Bond.rawValue, Cash.rawValue]
    static let colors = [
        UIColor(red: CGFloat(0.0/255), green: CGFloat(178.0/255), blue: CGFloat(220.0/255), alpha: 0.8),
        UIColor(red: CGFloat(255.0/255), green: CGFloat(47.0/255), blue: CGFloat(115.0/255), alpha: 0.8),
        UIColor(red: CGFloat(150.0/255), green: CGFloat(140.0/255), blue: CGFloat(138.0/255), alpha: 0.8),
        UIColor(red: CGFloat(255.0/255), green: CGFloat(148.0/255), blue: CGFloat(0.0/255), alpha: 0.8),
        UIColor(red: CGFloat(77.0/255), green: CGFloat(195.0/255), blue: CGFloat(33.0/255), alpha: 0.8),
    ]
}

class Position {
    var symbol: String
    var description: String
    var category: Category

    var price: Double
    var basis: Double

    var amount: UInt

    init(symbol: String, description: String, category: Category, price: Double, basis: Double, amount: UInt) {
        self.symbol = symbol
        self.description = description
        self.category = category
        self.price = price
        self.basis = basis
        self.amount = amount
    }
}