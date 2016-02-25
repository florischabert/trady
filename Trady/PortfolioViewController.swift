//
//  ViewController.swift
//  Trady
//
//  Created by Floris Chabert on 2/4/16.
//  Copyright © 2016 Floris Chabert. All rights reserved.
//`

import UIKit
import Charts

class PortfolioViewController: UITableViewController {

    var account: Account {
        if let accounts = etrade.accounts, account = accounts.first {
            return account
        }
        return Account(name: "Unknown", id: 0, value: 0)
    }

    var etrade: ETradeClient {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).etrade
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBarHidden = false
        navigationItem.hidesBackButton = true

        self.refreshControl = UIRefreshControl()
        self.refreshControl?.hidden = true
        self.refreshControl!.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl!.attributedTitle = NSAttributedString(string: "Pull to refresh your portfolio")
        self.tableView.contentOffset = CGPointMake(0, -self.refreshControl!.frame.size.height);
    }

    func refresh(sender: AnyObject) {
        (UIApplication.sharedApplication().delegate as! AppDelegate).etrade.update {
            dispatch_async(dispatch_get_main_queue(), {
                self.tableView.reloadData()
                self.refreshControl!.endRefreshing()
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func doTrading(sender: AnyObject) {

    }

}

extension PortfolioViewController: ChartViewDelegate {

    func createChart(chartView: PieChartView) {
        chartView.delegate = self
        chartView.legend.enabled = true
        chartView.descriptionText = ""
        chartView.usePercentValuesEnabled = true
        chartView.drawHoleEnabled = true
        chartView.holeTransparent = true
        chartView.transparentCircleRadiusPercent = 0.50
        chartView.holeRadiusPercent = 0.49
        chartView.rotationEnabled = false
        chartView.legend.position = .BelowChartCenter
        chartView.legend.form = .Circle
        chartView.legend.setCustom(colors: Category.colors, labels: Category.names)

        var categoryAmounts: [ChartDataEntry] = []
        var categoryNames: [String] = []

        for (index, category) in Category.allValues.enumerate() {
            let categoryList = account.positionsForCategory(category)

            var total = 0 as Double
            for position in categoryList {
                total += Double(position.amount) * position.price
            }

            if total / account.total < 0.1 {
                categoryNames.append("")
            }
            else {
                categoryNames.append(category.rawValue)
            }

            categoryAmounts.append(ChartDataEntry(value: Double(total * 100 / account.total), xIndex: index))
        }

        let pieChartDataSet = PieChartDataSet(yVals: categoryAmounts, label: "")
        pieChartDataSet.colors = Category.colors
        pieChartDataSet.sliceSpace = 1
        pieChartDataSet.valueTextColor = UIColor.whiteColor()
        pieChartDataSet.drawValuesEnabled = false
        pieChartDataSet.selectionShift = 5

        let pieChartData = PieChartData(xVals: categoryNames, dataSet: pieChartDataSet)
        chartView.data = pieChartData
    }

}

extension PortfolioViewController {

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if section <= 1 {
            return 1
        }

        return account.positions.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("AccountCell")! as UITableViewCell!
            cell.textLabel?.text = account.name
            cell.detailTextLabel?.text = "$\(account.value)"
            return cell
        }

        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier("PortfolioCell")! as UITableViewCell!
            createChart(cell.contentView.subviews[0] as! PieChartView)
            return cell
        }

        let cell = tableView.dequeueReusableCellWithIdentifier("PositionCell")! as UITableViewCell!

        let position = account.positions[indexPath.row]
        cell.textLabel?.text = position.symbol
        cell.detailTextLabel?.text = position.description

        let lineView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 45))
        lineView.backgroundColor = Category.colors[Category.allValues.indexOf { $0 == position.category }!]
        cell.contentView.addSubview(lineView)

        return cell
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return 3
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        if indexPath.section == 1 {
            return 238
        }

        return 45
    }

}

