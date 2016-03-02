//
//  SummaryCell.swift
//  Trady
//
//  Created by Floris Chabert on 2/29/16.
//  Copyright © 2016 Floris Chabert. All rights reserved.
//

import Charts
import UIKit

class SummaryCell: UITableViewCell, ChartViewDelegate {

    @IBOutlet weak var value: UILabel!
    @IBOutlet weak var change: UILabel!
    @IBOutlet weak var portfolio: UILabel!
    @IBOutlet weak var today: UILabel!
    @IBOutlet weak var chart: PieChartView!

    weak var portfolioController: PortfolioViewController?

    var app: AppDelegate {
        return (UIApplication.sharedApplication().delegate as! AppDelegate)
    }
    
    func update(account: Account) {
        if let _ = app.credentials {
            value.text = account.value.currency

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

        setupChart(account)
    }

    func setupChart(account: Account) {
        chart.delegate = self
        chart.legend.enabled = true
        chart.descriptionText = ""
        chart.usePercentValuesEnabled = true
        chart.drawHoleEnabled = true
        chart.holeTransparent = true
        chart.transparentCircleRadiusPercent = 0.47
        chart.holeRadiusPercent = 0.45
        chart.rotationEnabled = false
        chart.legend.position = .BelowChartCenter
        chart.legend.form = .Circle
        chart.legend.setCustom(colors: Category.colors, labels: Category.names)
        chart.userInteractionEnabled = app.credentials == nil ? false : true

        var ratios: [ChartDataEntry] = []
        var names: [String] = []
        var colors: [UIColor] = []

        if let _ = app.credentials {
            for (index, position) in account.positions.enumerate() {
                let ratio = (position.price * Double(position.quantity)) / account.value
                names.append( ratio > 0.1 ? position.symbol : "")
                colors.append(position.category.color)
                ratios.append(ChartDataEntry(value: ratio, xIndex: index))
            }
        }
        else {
            names.append("")
            colors.append(Category.allValues.first!.color)
            ratios.append(ChartDataEntry(value: 1, xIndex: 0))
        }

        let pieChartDataSet = PieChartDataSet(yVals: ratios, label: "")
        pieChartDataSet.colors = colors
        pieChartDataSet.sliceSpace = 1
        pieChartDataSet.valueTextColor = UIColor.whiteColor()
        pieChartDataSet.drawValuesEnabled = false
        pieChartDataSet.selectionShift = 6

        if let _ = app.credentials {
            if let expandedIndexPath = self.portfolioController?.expandedIndexPath {
                self.chart.highlightValues([ChartHighlight(xIndex: expandedIndexPath.row, dataSetIndex: 0)])
            }
            else {
                self.chart.highlightValues(nil)
            }
        }

        let pieChartData = PieChartData(xVals: names, dataSet: pieChartDataSet)
        chart.data = pieChartData
    }

    func chartValueSelected(chartView: Charts.ChartViewBase, entry: Charts.ChartDataEntry, dataSetIndex: Int, highlight: Charts.ChartHighlight) {
        portfolioController?.tableView.beginUpdates()
        portfolioController?.expandedIndexPath = NSIndexPath(forRow: entry.xIndex, inSection: 1)
        portfolioController?.tableView.endUpdates()

        if !portfolioController!.tableView.indexPathsForVisibleRows!.contains(portfolioController!.expandedIndexPath!) {
            portfolioController?.tableView.scrollToRowAtIndexPath(portfolioController!.expandedIndexPath!, atScrollPosition: .Middle, animated: true)
        }
    }

    func chartValueNothingSelected(chartView: Charts.ChartViewBase) {
        portfolioController?.tableView.beginUpdates()
        portfolioController?.expandedIndexPath = nil
        portfolioController?.tableView.endUpdates()
    }

}