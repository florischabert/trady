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

    var account: Account = Account("", value: 0, cash: 0)

    var app: AppDelegate {
        return (UIApplication.sharedApplication().delegate as! AppDelegate)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let data = NSUserDefaults.standardUserDefaults().objectForKey("account") as? NSData {
            account = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! Account
        }

        self.refreshControl = UIRefreshControl()
        self.refreshControl?.hidden = true
        self.refreshControl!.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)

        refresh(self)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if app.credentials == nil {
            self.performSegueWithIdentifier("link", sender: self)
        }
    }

    func refresh(sender: AnyObject) {
        if let credentials = app.credentials {
             app.ofx.getAccount(credentials) { account in
                if let account = account {
                    self.account = account

                    let defaults = NSUserDefaults.standardUserDefaults()
                    let data = NSKeyedArchiver.archivedDataWithRootObject(account) as NSData
                    defaults.removeObjectForKey("account")
                    defaults.setObject(data, forKey: "account")
                    defaults.synchronize()

                    dispatch_async(dispatch_get_main_queue()) {
                        self.tableView.reloadData()
                        self.refreshControl?.endRefreshing()
                    }
                }
                else {
                    dispatch_async(dispatch_get_main_queue()) {
                        let alert = UIAlertController(title: "Update", message: "Your porfolio could not be updated. Please try again later.", preferredStyle: UIAlertControllerStyle.Alert)
                        let alertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (UIAlertAction) -> Void in }
                        alert.addAction(alertAction)
                        self.presentViewController(alert, animated: true) {}
                    }
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
            var total: Double = 0
            for position in account.positions {
                if category == position.category {
                    total += Double(position.quantity) * position.price
                }
            }

            if total / account.value < 0.1 {
                categoryNames.append("")
            }
            else {
                categoryNames.append(category.rawValue)
            }

            categoryAmounts.append(ChartDataEntry(value: Double(total * 100 / account.value), xIndex: index))
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

        if section == 0 {
            return 1
        }

        return account.positions.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let formatter = NSNumberFormatter()
        formatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
        formatter.locale = NSLocale.currentLocale()

        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("PortfolioCell")! as UITableViewCell!
            createChart(cell.contentView.viewWithTag(23) as! PieChartView)

            let totalView = cell.contentView.viewWithTag(22) as! UITextView
            totalView.text = formatter.stringFromNumber(account.value) ?? "-"

            return cell
        }

        let cell = tableView.dequeueReusableCellWithIdentifier("PositionCell")! as UITableViewCell!

        let position = account.positions[indexPath.row]
        cell.textLabel?.text = position.symbol
        cell.detailTextLabel?.text = formatter.stringFromNumber(position.price * Double(position.quantity)) ?? "-"

        let lineView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 45))
        lineView.backgroundColor = Category.colors[Category.allValues.indexOf { $0 == position.category }!]
        cell.contentView.addSubview(lineView)

        return cell
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return 2
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        if indexPath.section == 0 {
            return 278
        }

        return 45
    }

}

extension UINavigationController {

    public func presentTransparentNavigationBar() {
        navigationBar.setBackgroundImage(UIImage(), forBarMetrics:UIBarMetrics.Default)
        navigationBar.translucent = true
        navigationBar.shadowImage = UIImage()
        setNavigationBarHidden(false, animated:true)
    }

    public func hideTransparentNavigationBar() {
        setNavigationBarHidden(true, animated:false)
        navigationBar.setBackgroundImage(UINavigationBar.appearance().backgroundImageForBarMetrics(UIBarMetrics.Default), forBarMetrics:UIBarMetrics.Default)
        navigationBar.translucent = UINavigationBar.appearance().translucent
        navigationBar.shadowImage = UINavigationBar.appearance().shadowImage
    }
}
