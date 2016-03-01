//
//  PositionCell.swift
//  Trady
//
//  Created by Floris Chabert on 2/29/16.
//  Copyright © 2016 Floris Chabert. All rights reserved.
//

import UIKit

class PositionCell: UITableViewCell {

    @IBOutlet weak var symbol: UILabel!
    @IBOutlet weak var descr: UILabel!
    @IBOutlet weak var change: UILabel!
    @IBOutlet weak var amount: UILabel!

    var app: AppDelegate {
        return (UIApplication.sharedApplication().delegate as! AppDelegate)
    }

    func update(account: Account, position: Position) {

        symbol.text = position.symbol
        descr.text = position.descr

        if let _ = app.credentials {
            if let changeValue = position.change {
                change.text = "\(position.price.currency) (\(String(format: "%.2f", 100 * changeValue / (position.price - changeValue)))%)"
            }
            if position.category == .Cash {
                change.text = "-"
            }

            amount.text = (position.price * Double(position.quantity)).currency
        }
        else {
            change.text = ""
            amount.text = ""
        }

        if let changeValue = position.change where change != 0  {
            if changeValue < 0 {
                change.textColor = UIColor(red: CGFloat(255.0/255), green: CGFloat(47.0/255), blue: CGFloat(115.0/255), alpha: 1)
            }
            else {
                change.textColor = UIColor(red: CGFloat(77.0/255), green: CGFloat(195.0/255), blue: CGFloat(33.0/255), alpha: 1)
            }
        }
        else {
            change.textColor = UIColor.blackColor()
        }

        var lineView = contentView.viewWithTag(42)
        if lineView == nil {
            lineView = UIView()
            lineView!.frame = CGRect(x: 0, y: 0, width: 5, height: contentView.frame.height)
            lineView!.tag = 42
            contentView.addSubview(lineView!)
        }
        lineView!.backgroundColor = position.category.color

        //        var ratioView = cell.contentView.viewWithTag(5)
        //        if ratioView == nil {
        //            ratioView = UIView()
        //            ratioView!.tag = 5
        //            ratioView!.alpha = 0.05
        //            cell.contentView.addSubview(ratioView!)
        //        }
        //        let ratioWidth = Double(cell.contentView.frame.width) * position.price * Double(position.quantity) / account.value
        //        ratioView!.frame = CGRect(x: 0, y: 0, width: ratioWidth, height:50)
        //        ratioView!.backgroundColor = position.category.color
    }
}