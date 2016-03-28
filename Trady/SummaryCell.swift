//
//  SummaryCell.swift
//  Trady
//
//  Created by Floris Chabert on 2/29/16.
//  Copyright © 2016 Floris Chabert. All rights reserved.
//

import Charts
import UIKit

class SummaryCell: UITableViewCell, ChartViewDelegate, UIScrollViewDelegate {

    @IBOutlet weak var value: UILabel!
    @IBOutlet weak var change: UILabel!
    @IBOutlet weak var portfolio: UILabel!
    @IBOutlet weak var today: UILabel!
    @IBOutlet weak var percentLabel: UILabel!

    @IBOutlet weak var chartScrollView: UIScrollView!
    @IBOutlet weak var pieChartView: PieChartView!
    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    weak var portfolioController: PortfolioViewController?

    var app: AppDelegate {
        return (UIApplication.sharedApplication().delegate as! AppDelegate)
    }
    
    func update(account: Account?) {

        chartScrollView.delegate = self

        change.text = "-"

        if let _ = app.credentials, account = account {
            value.text = account.value.currency
            value.text = "$000,000.00"

            change.text = ""
            percentLabel.text = ""
            if let changeValue = account.change {
                change.text = "\(account.change > 0 ? "+" : "")\(account.change?.currency ?? "-")"
                percentLabel.text = "\(changeValue > 0 ? "+" : "")\(String(format: "%.2f", 100 * changeValue / (account.value - changeValue)))%"
            }

            change.textColor = UIColor.blackColor()
            if account.change < 0 {
                change.textColor = UIColor(red: CGFloat(255.0/255), green: CGFloat(47.0/255), blue: CGFloat(115.0/255), alpha: 1)
            }
            else {
                change.textColor = UIColor(red: CGFloat(77.0/255), green: CGFloat(195.0/255), blue: CGFloat(33.0/255), alpha: 1)
            }
            percentLabel.textColor = change.textColor

            portfolio.hidden = false
            today.hidden = false
        }
        else {
            value.text = "Tap to Sync"
            change.text = "sensitive data hidden"
            change.textColor = UIColor.blackColor()

            portfolio.hidden = true
            today.hidden = true
        }

        if let _ = app.credentials, account = account {
            chartScrollView.hidden = false
            chartScrollView.contentSize.width = pieChartView.frame.size.width + lineChartView.frame.size.width
            createLineChart(account)
            createPieChart(account)
            pageControl.hidden = false
        }
        else {
            chartScrollView.hidden = true
            pageControl.hidden = true
        }
    }

    func createPieChart(account: Account) {
        pieChartView.delegate = self
        pieChartView.legend.enabled = false
        pieChartView.descriptionText = ""
        pieChartView.usePercentValuesEnabled = true
        pieChartView.drawHoleEnabled = true
        pieChartView.transparentCircleRadiusPercent = 0.41
        pieChartView.holeRadiusPercent = 0.38
        pieChartView.rotationEnabled = false
        pieChartView.userInteractionEnabled = false
        pieChartView.setExtraOffsets(left: 0, top: 0, right: 0, bottom: 5)

        var ratios: [ChartDataEntry] = []
        var names: [String] = []
        var colors: [UIColor] = []

        let positions = account.positions

        let ratio = account.cash / account.value
        names.append(ratio > 0.1 ? "Cash" : "")
        colors.append(PortfolioViewController.green)
        ratios.append(ChartDataEntry(value: ratio, xIndex: 0))

        for (index, position) in positions.enumerate() {
            let ratio = (position.price * position.quantity) / account.value
            names.append(ratio > 0.1 ? position.symbol : "")
            colors.append(PortfolioViewController.colors[index % PortfolioViewController.colors.count])
            ratios.append(ChartDataEntry(value: ratio, xIndex: index+1))
        }

        let pieChartDataSet = PieChartDataSet(yVals: ratios, label: "")
        pieChartDataSet.colors = colors
        pieChartDataSet.sliceSpace = 1
        pieChartDataSet.valueTextColor = UIColor.whiteColor()
        pieChartDataSet.drawValuesEnabled = false
        pieChartDataSet.selectionShift = 6

        let pieChartData = PieChartData(xVals: names, dataSet: pieChartDataSet)
        pieChartView.data = pieChartData
    }

    func createLineChart(account: Account?) {

        var dataSets: [LineChartDataSet] = []
        var names = [String]()

        var colors = [UIColor]()

        if let historical = YahooClient.historicalData["Portfolio"] {
            var dataEntries: [ChartDataEntry] = []
            for (i, data) in historical.enumerate() {
                let dataEntry = ChartDataEntry(value: data.close, xIndex: i)
                dataEntries.append(dataEntry)
                names.append(data.date)
            }
            dataSets.append(LineChartDataSet(yVals: dataEntries, label:"Portfolio"))
            colors.append(PortfolioViewController.blue)
        }

        for (i, set) in dataSets.enumerate() {
            set.drawCubicEnabled = true
            set.cubicIntensity = 0.1
            set.lineWidth = 2.3
            set.drawCirclesEnabled = false
            set.drawHorizontalHighlightIndicatorEnabled = false
            set.drawValuesEnabled = false

            set.setCircleColor(colors[i])
            set.setColor(colors[i])
        }
        let formatter = NSNumberFormatter()
        formatter.numberStyle = NSNumberFormatterStyle.PercentStyle
        formatter.locale = NSLocale.currentLocale()

        let lineChartData = LineChartData(xVals: names, dataSets: dataSets)
        lineChartView.data = lineChartData
        lineChartView.legend.enabled = true
        lineChartView.legend.position = .LeftOfChart
        lineChartView.legend.form = .Circle
        lineChartView.legend.formSize = 4
        lineChartView.legend.yOffset = 188
        lineChartView.legend.font = UIFont.systemFontOfSize(8)
        lineChartView.userInteractionEnabled = false
        lineChartView.descriptionText = ""
        lineChartView.leftAxis.enabled = true
        lineChartView.leftAxis.valueFormatter = formatter
        lineChartView.leftAxis.labelFont = UIFont.systemFontOfSize(8)
        lineChartView.leftAxis.drawTopYLabelEntryEnabled = false
        lineChartView.leftAxis.setLabelCount(2, force: true)
        lineChartView.leftAxis.labelPosition = .InsideChart
        lineChartView.leftAxis.drawLimitLinesBehindDataEnabled = false
        lineChartView.leftAxis.drawGridLinesEnabled = false
        lineChartView.leftAxis.drawAxisLineEnabled = false
        lineChartView.leftAxis.drawZeroLineEnabled = false
        lineChartView.rightAxis.enabled = false
        lineChartView.drawGridBackgroundEnabled = false
        lineChartView.drawBordersEnabled = false
        lineChartView.xAxis.enabled = true
        lineChartView.xAxis.drawGridLinesEnabled = false
        lineChartView.xAxis.drawAxisLineEnabled = false
        lineChartView.xAxis.labelPosition = .Bottom
        lineChartView.setViewPortOffsets(left: 0, top: 20, right: 0, bottom: 25)
        lineChartView.leftAxis.startAtZeroEnabled = false
    }

    func scrollViewDidScroll(scrollView: UIScrollView) {
        pageControl.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.size.width / 2)
        portfolioController?.summaryPie = pageControl.currentPage == 1
        portfolioController?.tableView.reloadData()
    }
    
}