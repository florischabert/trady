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

    func update(account: Account?, position: Position?, extraSymbol: String?, index: Int) {
        if position == nil && extraSymbol == nil {
            symbol.text = "Cash"
            change.text = app.credentials == nil ? "-" : account!.cash.currency
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
            lineView!.backgroundColor = UIColor.clearColor()

            self.contentView.alpha = 1

            return
        }

        let symbolString = position?.symbol ?? extraSymbol!

        symbol.text = symbolString
        descr.text = YahooClient.quotes[symbolString]?.descr ?? position?.descr ?? "-"

        if let price = YahooClient.quotes[symbolString]?.price,
            changeValue = YahooClient.quotes[symbolString]?.change {
            change.text = "\(changeValue > 0 ? "+" : "")\(String(format: "%.2f", 100 * changeValue / (price - changeValue)))%"
            change.textColor = changeValue < 0 ? PortfolioViewController.red : PortfolioViewController.green
        }
        else {
            change.text = ""
            change.textColor = UIColor.clearColor()
        }

        details.text = ""
        if position == nil || position?.category == .Fund || position?.category == .Equity {

            let price = YahooClient.quotes[symbolString]?.price ?? position?.price
            if let price = price {
                amount.text = (app.credentials == nil || position == nil) ? price.currency : "\(Int(position!.quantity))x \(price.currency)"
            }
            else {
                amount.text = "-"
            }

            if let cap = YahooClient.quotes[symbolString]?.cap {
                details!.text! += "Market Capitalization: \(cap)"
            }
            if let pe = YahooClient.quotes[symbolString]?.pe {
                details!.text! += "  |  P/E: \(pe)"
            }
        }
        else if position?.category == .Bond {
            amount.text = (position!.quantity * position!.price).currency
            change.text = "-"
        }
        else if position?.category == .Option {
            amount.text = position!.price.currency
            change.text = "-"
        }

        self.contentView.alpha = extraSymbol != nil ? 0.6 : 1

        var lineView = contentView.viewWithTag(42)
        if lineView == nil {
            lineView = UIView()
            lineView!.frame = CGRect(x: 0, y: 0, width: 5, height: 55)
            lineView!.tag = 42
            contentView.addSubview(lineView!)
        }
        lineView!.backgroundColor = UIColor.clearColor()
        if portfolioController!.summaryPie {
            lineView!.backgroundColor = PortfolioViewController.colors[index % PortfolioViewController.colors.count]
        }
        if extraSymbol != nil {
            lineView!.backgroundColor = UIColor.clearColor()
        }

        chart.hidden = !expanded
        volumeChart.hidden = !expanded
        details.hidden = !expanded

        createChart(symbolString, index: index)
        createVolumeChart(symbolString, index: index)
    }

    func createChart(symbol: String, index: Int) {
        var names: [String] = []
        var dataEntries: [ChartDataEntry] = []

        if let historical = YahooClient.historicalData[symbol] {
            for (i, data) in historical.enumerate() {
                let dataEntry = ChartDataEntry(value: data.close, xIndex: i)
                dataEntries.append(dataEntry)
                names.append(data.date)
            }
        }

        if names.count > 2 {
            names[0] = ""
            names[names.count-2] = ""
        }

        var color = change.textColor
        if portfolioController!.summaryPie {
            color = PortfolioViewController.colors[index % PortfolioViewController.colors.count]
        }

        let lineChartDataSet = LineChartDataSet(yVals: dataEntries, label: symbol)
        lineChartDataSet.drawCubicEnabled = true
        lineChartDataSet.cubicIntensity = 0.1
        lineChartDataSet.lineWidth = 2.3
        lineChartDataSet.drawHorizontalHighlightIndicatorEnabled = false
        lineChartDataSet.setCircleColor(color)
        lineChartDataSet.setColor(color)
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

    func createVolumeChart(symbol: String, index: Int) {
        var names: [String] = []
        var dataEntries: [ChartDataEntry] = []

        if let historical = YahooClient.historicalData[symbol] {
            for (i, data) in historical.enumerate() {
                let dataEntry = BarChartDataEntry(value: data.volume, xIndex: i)
                dataEntries.append(dataEntry)
                names.append("")
            }
        }

        var color = change.textColor
        if portfolioController!.summaryPie {
            color = PortfolioViewController.colors[index % PortfolioViewController.colors.count]
        }
        
        let barChartDataSet = BarChartDataSet(yVals: dataEntries, label: nil)
        barChartDataSet.drawValuesEnabled = false
        barChartDataSet.setColor(color)

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
        volumeChart.alpha = 0.1
    }
}