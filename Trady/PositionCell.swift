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
            if position.change < 0 {
                colorChange = Category.Fund.color
            }
            else {
                colorChange = Category.Cash.color
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

        var dataEntries: [ChartDataEntry] = []
        for i in 0..<12 {
            let dataEntry = ChartDataEntry(value: Double(20) + Double(rand()%10), xIndex: i)
            dataEntries.append(dataEntry)
        }

        let lineChartDataSet = LineChartDataSet(yVals: dataEntries, label: position.symbol)
        lineChartDataSet.drawCubicEnabled = true
        lineChartDataSet.cubicIntensity = 0.1
        lineChartDataSet.lineWidth = 2.3
        lineChartDataSet.circleRadius = 4
        lineChartDataSet.fillColor = UIColor.blueColor()
        lineChartDataSet.fillAlpha = 1
        lineChartDataSet.drawHorizontalHighlightIndicatorEnabled = false
        lineChartDataSet.setCircleColor(position.category.color)
        lineChartDataSet.setColor(position.category.color)
        lineChartDataSet.drawValuesEnabled = false
        lineChartDataSet.valueFont = UIFont.systemFontOfSize(8)

        let formatter = NSNumberFormatter()
        formatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
        formatter.locale = NSLocale.currentLocale()
        lineChartDataSet.valueFormatter = formatter

        let names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let lineChartData = LineChartData(xVals: names, dataSet: lineChartDataSet)
        chart.data = lineChartData
        chart.legend.enabled = false
        chart.userInteractionEnabled = false
        chart.descriptionText = ""
        chart.leftAxis.enabled = false
        chart.rightAxis.enabled = false
        chart.rightAxis.valueFormatter = formatter
        chart.rightAxis.labelFont = UIFont.systemFontOfSize(9)
        chart.rightAxis.labelTextColor = position.category.color
        chart.rightAxis.drawTopYLabelEntryEnabled = false
        chart.rightAxis.setLabelCount(6, force: false)
        chart.rightAxis.labelPosition = .InsideChart
        chart.rightAxis.drawLimitLinesBehindDataEnabled = false
        chart.rightAxis.drawGridLinesEnabled = false
        chart.rightAxis.drawAxisLineEnabled = false
        chart.drawGridBackgroundEnabled = false
        chart.drawBordersEnabled = false
        chart.xAxis.drawGridLinesEnabled = false
        chart.xAxis.drawAxisLineEnabled = false
        chart.xAxis.labelPosition = .Bottom
        chart.setViewPortOffsets(left: 20, top: 0, right: 20, bottom: 20)
        chart.leftAxis.startAtZeroEnabled = false
    }
}