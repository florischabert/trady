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
    @IBOutlet weak var chart: LineChartView!

    weak var portfolioController: PortfolioViewController?

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

        let prices: [Double] = [10, 11, 14, 12, 14, 17, 18, 9, 11, 10]
        let names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct"]

        var dataEntries: [ChartDataEntry] = []
        for (i, value) in prices.enumerate() {
            let dataEntry = ChartDataEntry(value: value, xIndex: i)
            dataEntries.append(dataEntry)
        }

        let lineChartDataSet = LineChartDataSet(yVals: dataEntries, label: "$")
        lineChartDataSet.drawCubicEnabled = true
        lineChartDataSet.cubicIntensity = 0.2
        lineChartDataSet.lineWidth = 2.3
        lineChartDataSet.circleRadius = 4
        lineChartDataSet.fillColor = UIColor.blueColor()
        lineChartDataSet.fillAlpha = 1
        lineChartDataSet.drawHorizontalHighlightIndicatorEnabled = false
        lineChartDataSet.setCircleColor(position.category.color)
        lineChartDataSet.setColor(position.category.color)
        lineChartDataSet.drawValuesEnabled = false

        let lineChartData = LineChartData(xVals: names, dataSet: lineChartDataSet)
        chart.data = lineChartData
        chart.legend.enabled = false
        chart.userInteractionEnabled = false
        chart.descriptionText = ""
        chart.leftAxis.enabled = false
        chart.rightAxis.enabled = false
        chart.drawGridBackgroundEnabled = false
        chart.drawBordersEnabled = false
        chart.xAxis.drawGridLinesEnabled = false
        chart.xAxis.drawAxisLineEnabled = false
        chart.xAxis.labelPosition = .Bottom
        chart.setViewPortOffsets(left: 20, top: 20, right: 20, bottom: 20)

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