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
    @IBOutlet weak var volumeChart: BarChartView!
    @IBOutlet weak var details: UILabel!
    
    var expanded = false

    weak var portfolioController: PortfolioViewController?

    var app: AppDelegate {
        return (UIApplication.sharedApplication().delegate as! AppDelegate)
    }

    func update(account: Account, index: Int) {

        if index == -1 {
            symbol.text = "Cash"
            change.text = app.credentials == nil ? "-" : account.cash.currency
            change.font = UIFont.systemFontOfSize(12)
            change.textColor = UIColor.blackColor()
            descr.text = ""
            amount.text = ""

            chart.hidden = true

            var lineView = contentView.viewWithTag(42)
            if lineView == nil {
                lineView = UIView()
                lineView!.frame = CGRect(x: 0, y: 0, width: 5, height: 55)
                lineView!.tag = 42
                contentView.addSubview(lineView!)
            }
            lineView!.backgroundColor = PortfolioViewController.green

            return
        }

        let position = account.positions[index]

        symbol.text = position.symbol
        descr.text = YahooClient.quotes[position.symbol]?.descr ?? position.descr

        if let changeValue = YahooClient.quotes[position.symbol]?.change {
            if app.credentials == nil {
                change.text = "\(changeValue > 0 ? "+" : "")\(String(format: "%.2f", 100 * changeValue / (YahooClient.quotes[position.symbol]!.price - changeValue)))%"
            }
            else {
                change.text = "\(changeValue > 0 ? "+" : "")\((changeValue * position.quantity).currency) \(changeValue > 0 ? "+" : "")\(String(format: "%.2f", 100 * changeValue / (YahooClient.quotes[position.symbol]!.price - changeValue)))%"

                let attributedText = NSMutableAttributedString(attributedString: change.attributedText!)
                let length = change.text!.startIndex.distanceTo(change.text!.rangeOfString(" ")!.endIndex)
                attributedText.setAttributes([NSFontAttributeName: UIFont.systemFontOfSize(change.font.pointSize-2)], range: NSMakeRange(0, length))
                change.attributedText = attributedText

            }
            change.textColor = changeValue < 0 ? PortfolioViewController.red : PortfolioViewController.green
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
            let price = YahooClient.quotes[position.symbol]?.price ?? position.price
            amount.text = app.credentials == nil ? price.currency : "\(Int(position.quantity))x \(price.currency)"

            if let cap = YahooClient.quotes[position.symbol]?.cap {
                details!.text! += "Market Capitalization: \(cap)"
            }
            if let pe = YahooClient.quotes[position.symbol]?.pe {
                details!.text! += "  |  P/E: \(pe)"
            }
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
        lineView!.backgroundColor = PortfolioViewController.colors[index % PortfolioViewController.colors.count]

        chart.hidden = !expanded
        createChart(position, index: index)
        createVolumeChart(position, index: index)
    }

    func createChart(position: Position, index: Int) {
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

        if names.count > 2 {
            names[0] = ""
            names[names.count-2] = ""
        }

        let lineChartDataSet = LineChartDataSet(yVals: dataEntries, label: position.symbol)
        lineChartDataSet.drawCubicEnabled = true
        lineChartDataSet.cubicIntensity = 0.1
        lineChartDataSet.lineWidth = 2.3
        lineChartDataSet.drawHorizontalHighlightIndicatorEnabled = false
        lineChartDataSet.setCircleColor(PortfolioViewController.colors[index % PortfolioViewController.colors.count])
        lineChartDataSet.setColor(PortfolioViewController.colors[index % PortfolioViewController.colors.count])
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
        chart.leftAxis.labelFont = UIFont.systemFontOfSize(8)
        chart.leftAxis.drawTopYLabelEntryEnabled = false
        chart.leftAxis.setLabelCount(2, force: false)
        chart.leftAxis.labelPosition = .InsideChart
        chart.leftAxis.drawLimitLinesBehindDataEnabled = false
        chart.leftAxis.drawGridLinesEnabled = false
        chart.leftAxis.drawAxisLineEnabled = false
        chart.leftAxis.drawZeroLineEnabled = false
        chart.drawGridBackgroundEnabled = false
        chart.drawBordersEnabled = false
        chart.xAxis.drawGridLinesEnabled = false
        chart.xAxis.drawAxisLineEnabled = false
        chart.xAxis.labelPosition = .Bottom
        chart.xAxis.labelFont = UIFont.systemFontOfSize(9)
        chart.setViewPortOffsets(left: 0, top: 0, right: 0, bottom: 20)
        chart.leftAxis.startAtZeroEnabled = false

        chart.backgroundColor = UIColor.clearColor()
    }

    func createVolumeChart(position: Position, index: Int) {
        var names: [String] = []
        var dataEntries: [ChartDataEntry] = []

        if let historical = YahooClient.historicalData[position.symbol] {
            for (i, data) in historical.enumerate() {
                let dataEntry = BarChartDataEntry(value: data.volume, xIndex: i)
                dataEntries.append(dataEntry)
                names.append("")
            }
        }

        let barChartDataSet = BarChartDataSet(yVals: dataEntries, label: nil)
        barChartDataSet.drawValuesEnabled = false
        barChartDataSet.setColor(PortfolioViewController.colors[index % PortfolioViewController.colors.count])

        let barChartData = BarChartData(xVals: names, dataSet: barChartDataSet)
        volumeChart.data = barChartData
        volumeChart.legend.enabled = false
        volumeChart.userInteractionEnabled = false
        volumeChart.descriptionText = ""
        volumeChart.rightAxis.enabled = false
        volumeChart.leftAxis.enabled = false
        volumeChart.drawGridBackgroundEnabled = false
        volumeChart.drawBordersEnabled = false
        volumeChart.xAxis.enabled = false
        volumeChart.setViewPortOffsets(left: 0, top: 0, right: 0, bottom: 0)
        volumeChart.alpha = 0.08
    }
}