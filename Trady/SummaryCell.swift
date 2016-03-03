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

    @IBOutlet weak var chartScrollView: UIScrollView!
    @IBOutlet weak var pieChartView: PieChartView!
    @IBOutlet weak var lineChartView: LineChartView!

    weak var portfolioController: PortfolioViewController?

    var app: AppDelegate {
        return (UIApplication.sharedApplication().delegate as! AppDelegate)
    }
    
    func update(account: Account) {
        chartScrollView.contentSize.width = pieChartView.frame.size.width + lineChartView.frame.size.width

        if let _ = app.credentials {
            value.text = account.value.currency
            change.text = "-"

            var text = account.change?.currency ?? "-"
            if let changeValue = account.change {
                text += " \(changeValue > 0 ? "+" : "")\(String(format: "%.2f", 100 * changeValue / (account.value - changeValue)))%"

                change.text = text
                
                let attributedText = NSMutableAttributedString(attributedString: change.attributedText!)
                let start = change.text!.startIndex.distanceTo(change.text!.rangeOfString(" ")!.endIndex)
                let length = change.text!.rangeOfString(" ")!.endIndex.distanceTo(change.text!.endIndex)
                attributedText.setAttributes([NSFontAttributeName: UIFont.boldSystemFontOfSize(change.font.pointSize)], range: NSMakeRange(start, length))
                change.attributedText = attributedText
            }
            change.textColor = UIColor.blackColor()

            if account.change < 0 {
                change.textColor = UIColor(red: CGFloat(255.0/255), green: CGFloat(47.0/255), blue: CGFloat(115.0/255), alpha: 1)
            }
            else {
                change.textColor = UIColor(red: CGFloat(77.0/255), green: CGFloat(195.0/255), blue: CGFloat(33.0/255), alpha: 1)
            }

            portfolio.hidden = false
            today.hidden = false
        }
        else {
            value.text = "Pull to Refresh"

            change.textColor = UIColor.blackColor()
            change.text = "Sensitive data requires identification"

            portfolio.hidden = true
            today.hidden = true
        }

        createLineChart(account)
        createPieChart(account)
    }

    func createPieChart(account: Account) {
        pieChartView.delegate = self
        pieChartView.legend.enabled = true
        pieChartView.descriptionText = ""
        pieChartView.usePercentValuesEnabled = true
        pieChartView.drawHoleEnabled = true
        pieChartView.holeTransparent = true
        pieChartView.transparentCircleRadiusPercent = 0.47
        pieChartView.holeRadiusPercent = 0.45
        pieChartView.rotationEnabled = false
        pieChartView.legend.position = .BelowChartCenter
        pieChartView.legend.form = .Circle
        pieChartView.legend.setCustom(colors: Category.colors, labels: Category.names)
        pieChartView.userInteractionEnabled = false
        pieChartView.hidden = app.credentials == nil ? true : false

        var ratios: [ChartDataEntry] = []
        var names: [String] = []
        var colors: [UIColor] = []

        for (index, position) in account.positions.enumerate() {
            let ratio = (position.price * position.quantity) / account.value
            names.append("")
            colors.append(position.category.color)
            ratios.append(ChartDataEntry(value: ratio, xIndex: index))
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

    func createLineChart(account: Account) {

        var dataSets: [LineChartDataSet] = []

        if let _ = app.credentials {
            var dataEntries: [ChartDataEntry] = []
            for i in 0..<12 {
                let dataEntry = ChartDataEntry(value: Double(10) + Double(rand()%10), xIndex: i)
                dataEntries.append(dataEntry)
            }
            dataSets.append(LineChartDataSet(yVals: dataEntries, label: "Portfolio"))
        }

        for symbol in ["S&P 500 Index"] {
            var dataEntries: [ChartDataEntry] = []
            for i in 0..<12 {
                let dataEntry = ChartDataEntry(value: Double(10) + Double(rand()%10), xIndex: i)
                dataEntries.append(dataEntry)
            }
            dataSets.append(LineChartDataSet(yVals: dataEntries, label: symbol))
        }

        for (i, set) in dataSets.enumerate() {
            set.drawCubicEnabled = true
            set.cubicIntensity = 0.1
            set.lineWidth = 2.3
            set.circleRadius = 4
            set.drawHorizontalHighlightIndicatorEnabled = false
            set.drawValuesEnabled = false

            let color = Category.allValues[i].color
            set.setCircleColor(color)
            set.setColor(color)
        }

        let names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let lineChartData = LineChartData(xVals: names, dataSets: dataSets)
        lineChartView.data = lineChartData
        lineChartView.legend.enabled = true
        lineChartView.legend.yEntrySpace = 20
        lineChartView.legend.position = .BelowChartCenter
        lineChartView.legend.form = .Line
        lineChartView.userInteractionEnabled = false
        lineChartView.descriptionText = ""
        lineChartView.leftAxis.enabled = false
        lineChartView.rightAxis.enabled = false
        lineChartView.drawGridBackgroundEnabled = false
        lineChartView.drawBordersEnabled = false
        lineChartView.xAxis.enabled = false
        lineChartView.xAxis.drawGridLinesEnabled = true
        lineChartView.xAxis.drawAxisLineEnabled = false
        lineChartView.xAxis.labelPosition = .Bottom
        lineChartView.setViewPortOffsets(left: 20, top: 15, right: 20, bottom: 30)
        lineChartView.leftAxis.startAtZeroEnabled = false
    }

}