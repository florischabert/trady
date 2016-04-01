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

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var pieChartView: PieChartView!

    weak var portfolioController: PortfolioViewController?

    var app: AppDelegate {
        return (UIApplication.sharedApplication().delegate as! AppDelegate)
    }
    
    func update(account: Account?) {

        if let _ = app.credentials, account = account {

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = NSTextAlignment.Center

            let attributedString = NSMutableAttributedString(
                string: "Your portfolio is \(account.change < 0 ? "down" : "up") ",
                attributes: [
                    NSForegroundColorAttributeName: UIColor.blackColor(),
                    NSFontAttributeName: UIFont.systemFontOfSize(16),
                    NSParagraphStyleAttributeName: paragraphStyle
                ]
            )

            var changeColor = UIColor.blackColor()
            if account.change < 0 {
                changeColor = UIColor(red: CGFloat(255.0/255), green: CGFloat(47.0/255), blue: CGFloat(115.0/255), alpha: 1)
            }
            else {
                changeColor = UIColor(red: CGFloat(77.0/255), green: CGFloat(195.0/255), blue: CGFloat(33.0/255), alpha: 1)
            }

            let changeString = NSAttributedString(
                string: "\(String(format: "%.2f", abs(100 * account.change! / (account.value - account.change!))))%",
                attributes: [
                    NSForegroundColorAttributeName: changeColor,
                    NSFontAttributeName: UIFont.systemFontOfSize(17),
                    NSParagraphStyleAttributeName: paragraphStyle
                ]
            )
            attributedString.appendAttributedString(changeString)

            let todayString = NSAttributedString(
                string: " today\n",
                attributes: [
                    NSForegroundColorAttributeName: UIColor.blackColor(),
                    NSFontAttributeName: UIFont.systemFontOfSize(16),
                    NSParagraphStyleAttributeName: paragraphStyle
                ]
            )
            attributedString.appendAttributedString(todayString)

            let valueString = NSAttributedString(
                string: account.value.currency,
                attributes: [
                    NSForegroundColorAttributeName: UIColor.blackColor(),
                    NSFontAttributeName: UIFont.boldSystemFontOfSize(16),
                    NSParagraphStyleAttributeName: paragraphStyle
                ]
            )
            attributedString.appendAttributedString(valueString)

            let assetsString = NSAttributedString(
                string: " in assets",
                attributes: [
                    NSForegroundColorAttributeName: UIColor.blackColor(),
                    NSFontAttributeName: UIFont.systemFontOfSize(17),
                    NSParagraphStyleAttributeName: paragraphStyle
                ]
            )
            attributedString.appendAttributedString(assetsString)


            textView.attributedText = attributedString
        }
        else {
            textView.text = "Sensitive data is hidden\nTap to sync"
        }

        if let _ = app.credentials, account = account {
            createPieChart(account)
        }
    }

    func createPieChart(account: Account) {
        pieChartView.delegate = self
        pieChartView.legend.enabled = false
        pieChartView.descriptionText = ""
        pieChartView.usePercentValuesEnabled = true
        pieChartView.drawHoleEnabled = true
        pieChartView.transparentCircleRadiusPercent = 0.47
        pieChartView.holeRadiusPercent = 0.45
        pieChartView.rotationEnabled = false
        pieChartView.userInteractionEnabled = true
        pieChartView.setExtraOffsets(left: 0, top: 0, right: 0, bottom: 14)

        var ratios: [ChartDataEntry] = []
        var names: [String] = []
        var colors: [UIColor] = []

        let positions = account.positions

        let ratio = account.cash / account.value
        names.append("")
        colors.append(PortfolioViewController.green)
        ratios.append(ChartDataEntry(value: ratio, xIndex: 0))

        for (index, position) in positions.enumerate() {
            let ratio = (position.price * position.quantity) / account.value
            names.append("")
            colors.append(PortfolioViewController.colors[index % PortfolioViewController.colors.count])
            ratios.append(ChartDataEntry(value: ratio, xIndex: index+1))
        }

        let pieChartDataSet = PieChartDataSet(yVals: ratios, label: "")
        pieChartDataSet.colors = colors
        pieChartDataSet.sliceSpace = 1
        pieChartDataSet.valueTextColor = UIColor.whiteColor()
        pieChartDataSet.drawValuesEnabled = false
        pieChartDataSet.selectionShift = 4

        let pieChartData = PieChartData(xVals: names, dataSet: pieChartDataSet)
        pieChartView.data = pieChartData
    }

    func chartValueSelected(chartView: ChartViewBase, entry: ChartDataEntry, dataSetIndex: Int, highlight: ChartHighlight) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.Center

        var text = ""
        var color = UIColor.blackColor()
        if entry.xIndex == 0 {
            text = "Cash"
            color = PortfolioViewController.green
        }
        else {
            let position = portfolioController?.account?.positions[entry.xIndex-1]
            text = position!.symbol
            color = PortfolioViewController.colors[(entry.xIndex-1) % PortfolioViewController.colors.count]
        }

        let attributedText = NSMutableAttributedString(
            string: "\(text)\n",
            attributes: [
                NSForegroundColorAttributeName: color,
                NSFontAttributeName: UIFont.boldSystemFontOfSize(16),
                NSParagraphStyleAttributeName: paragraphStyle
            ]
        )

        let percentText = NSMutableAttributedString(
            string: "\(String(format: "%.0f", entry.value*100))%",
            attributes: [
                NSForegroundColorAttributeName: UIColor.blackColor(),
                NSFontAttributeName: UIFont.boldSystemFontOfSize(10),
                NSParagraphStyleAttributeName: paragraphStyle
            ]
        )
        attributedText.appendAttributedString(percentText)

        pieChartView.centerAttributedText = attributedText
    }

    func chartValueNothingSelected(chartView: ChartViewBase) {
        pieChartView.centerText = ""
    }

}