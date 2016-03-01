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
    @IBOutlet weak var chartPercentage: UILabel!

    var app: AppDelegate {
        return (UIApplication.sharedApplication().delegate as! AppDelegate)
    }
    
    func update(account: Account) {
        if let _ = app.credentials {
            value.text = account.value.currency

            var text = account.change?.currency ?? "-"
            if let change = account.change {
                text += " (\(String(format: "%.2f", 100 * change / (account.value - change)))%)"
            }
            change.text = text

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

        var ratios: [ChartDataEntry] = []
        var names: [String] = []
        var colors: [UIColor] = []

        for (index, position) in account.positions.enumerate() {
            let ratio = (position.price * Double(position.quantity)) / account.value
            if let _ = (UIApplication.sharedApplication().delegate as! AppDelegate).credentials {
                names.append( ratio > 0.1 ? position.symbol : "")
                colors.append(position.category.color)
            }
            else {
                names.append("")
                colors.append(Category.Equity.color)
            }
            ratios.append(ChartDataEntry(value: ratio, xIndex: index))
        }

        let pieChartDataSet = PieChartDataSet(yVals: ratios, label: "")
        pieChartDataSet.colors = colors
        pieChartDataSet.sliceSpace = 1
        pieChartDataSet.valueTextColor = UIColor.whiteColor()
        pieChartDataSet.drawValuesEnabled = false
        pieChartDataSet.selectionShift = 6

        let pieChartData = PieChartData(xVals: names, dataSet: pieChartDataSet)
        chart.data = pieChartData
    }

    func chartValueSelected(chartView: Charts.ChartViewBase, entry: Charts.ChartDataEntry, dataSetIndex: Int, highlight: Charts.ChartHighlight) {
        chartPercentage.text = "\(String(format: "%.1f", entry.value*100))%"
    }

    func chartValueNothingSelected(chartView: Charts.ChartViewBase) {
        chartPercentage.text = ""
    }

}