//
//  PositionCell.swift
//  Trady
//
//  Created by Floris Chabert on 2/29/16.
//  Copyright © 2016 Floris Chabert. All rights reserved.
//

import Charts
import UIKit

class PositionCell: UITableViewCell {

    @IBOutlet weak var symbol: UILabel!
    @IBOutlet weak var descr: UILabel!
    @IBOutlet weak var change: UILabel!
    @IBOutlet weak var amount: UILabel!
    @IBOutlet weak var chart: UIView!

    var app: AppDelegate {
        return (UIApplication.sharedApplication().delegate as! AppDelegate)
    }

    func update(account: Account, position: Position) {

        symbol.text = position.symbol
        descr.text = position.descr

        if let changeValue = position.change {
            change.text = "\(position.price.currency) \(changeValue > 0 ? "+" : "")\(String(format: "%.2f", 100 * changeValue / (position.price - changeValue)))%"

            var colorChange = UIColor.blackColor()
            if account.change < 0 {
                colorChange = UIColor(red: CGFloat(255.0/255), green: CGFloat(47.0/255), blue: CGFloat(115.0/255), alpha: 1)
            }
            else {
                colorChange = UIColor(red: CGFloat(77.0/255), green: CGFloat(195.0/255), blue: CGFloat(33.0/255), alpha: 1)
            }

            let attributedText = NSMutableAttributedString(attributedString: change.attributedText!)
            let start = change.text!.startIndex.distanceTo(change.text!.rangeOfString(" ")!.endIndex)
            let length = change.text!.rangeOfString(" ")!.endIndex.distanceTo(change.text!.endIndex)
            attributedText.setAttributes([
                NSFontAttributeName: UIFont.boldSystemFontOfSize(change.font.pointSize),
                NSForegroundColorAttributeName: colorChange
                ], range: NSMakeRange(start, length))
            change.attributedText = attributedText
        }
        else {
            change.text = ""
        }

        if position.category == .Cash {
            change.text = "-"
        }

        if let _ = app.credentials {
            amount.text = (position.price * Double(position.quantity)).currency
        }
        else {
            amount.text = ""
        }

        var lineView = contentView.viewWithTag(42)
        if lineView == nil {
            lineView = UIView()
            lineView!.frame = CGRect(x: 0, y: 0, width: 5, height: 55)
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