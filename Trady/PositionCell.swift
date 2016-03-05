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
    @IBOutlet weak var details: UILabel!
    
    var expanded = false

    weak var portfolioController: PortfolioViewController?

    var app: AppDelegate {
        return (UIApplication.sharedApplication().delegate as! AppDelegate)
    }

    func update(account: Account, position: Position) {

        symbol.text = position.symbol
        descr.text = position.descr

        if let changeValue = position.change {
            change.text = "\(changeValue > 0 ? "+" : "")\(String(format: "%.2f", 100 * changeValue / (position.price - changeValue)))%"
            change.textColor = position.change < 0 ? Category.Fund.color : Category.Cash.color
        }
        else {
            change.text = ""
            change.textColor = UIColor.blackColor()
        }

        if position.category != .Fund && position.category != .Equity {
            change.text = "-"
        }

        details.text = ""
        if position.category == .Fund || position.category == .Equity {
            amount.text = app.credentials == nil ? position.price.currency : "\(Int(position.quantity))x \(position.price.currency)"

            if let cap = position.cap {
                details!.text! += "Capitalization: \(cap)"
            }
            if let pe = position.pe {
                details!.text! += "  |  P/E: \(pe)"
            }
        }
        else if position.category == .Cash {
            amount.text = app.credentials == nil ? "-" : position.price.currency
        }
        else if position.category == .Bond {
            amount.text = (position.quantity * position.price).currency
        }
        else if position.category == .Option {
            amount.text = position.price.currency
        }

        var lineView = contentView.viewWithTag(42)
        if lineView == nil {
            lineView = UIView()
            lineView!.frame = CGRect(x: 0, y: 0, width: 5, height: 55)
            lineView!.tag = 42
            contentView.addSubview(lineView!)
        }
        lineView!.backgroundColor = position.category.color

        chart.hidden = !expanded
        createChart(position)
    }

    func createChart(position: Position) {
        var names: [String] = []
        var dataEntries: [ChartDataEntry] = []

        if let historical = YahooClient.historicalData[position.symbol] {
            for (i, data) in historical.enumerate() {
                let dataEntry = ChartDataEntry(value: data.close, xIndex: i)
                dataEntries.append(dataEntry)
                names.append(data.date)
            }
        }
        else {
            dataEntries.append(ChartDataEntry(value: position.price, xIndex: 0))
            dataEntries.append(ChartDataEntry(value: position.price, xIndex: 1))
            names = ["", "Today"]
        }

        names[0] = ""
        names[names.count-2] = ""

        let lineChartDataSet = LineChartDataSet(yVals: dataEntries, label: position.symbol)
        lineChartDataSet.drawCubicEnabled = true
        lineChartDataSet.cubicIntensity = 0.1
        lineChartDataSet.lineWidth = 2.3
        lineChartDataSet.drawHorizontalHighlightIndicatorEnabled = false
        lineChartDataSet.setCircleColor(position.category.color)
        lineChartDataSet.setColor(position.category.color)
        lineChartDataSet.drawCirclesEnabled = false
        lineChartDataSet.drawValuesEnabled = false
        lineChartDataSet.valueFont = UIFont.systemFontOfSize(8)

        let formatter = NSNumberFormatter()
        formatter.numberStyle = NSNumberFormatterStyle.PercentStyle
        formatter.locale = NSLocale.currentLocale()
        lineChartDataSet.valueFormatter = formatter

        let lineChartData = LineChartData(xVals: names, dataSet: lineChartDataSet)
        chart.data = lineChartData
        chart.legend.enabled = false
        chart.userInteractionEnabled = false
        chart.descriptionText = ""
        chart.rightAxis.enabled = false
        chart.leftAxis.enabled = true
        chart.leftAxis.valueFormatter = formatter
        chart.leftAxis.labelFont = UIFont.boldSystemFontOfSize(9)
        chart.leftAxis.labelTextColor = position.category.color
        chart.leftAxis.drawTopYLabelEntryEnabled = false
        chart.leftAxis.setLabelCount(2, force: false)
        chart.leftAxis.labelPosition = .InsideChart
        chart.leftAxis.drawLimitLinesBehindDataEnabled = false
        chart.leftAxis.drawGridLinesEnabled = false
        chart.leftAxis.drawAxisLineEnabled = false
        chart.drawGridBackgroundEnabled = false
        chart.drawBordersEnabled = false
        chart.xAxis.drawGridLinesEnabled = false
        chart.xAxis.drawAxisLineEnabled = false
        chart.xAxis.labelPosition = .Bottom
        chart.xAxis.labelFont = UIFont.systemFontOfSize(9)
        chart.setViewPortOffsets(left: 0, top: 0, right: 0, bottom: 20)
        chart.leftAxis.startAtZeroEnabled = false
    }
}