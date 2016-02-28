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
    var backgrounded = false

    var app: AppDelegate {
        return (UIApplication.sharedApplication().delegate as! AppDelegate)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let statusView = UIView()
        statusView.frame = CGRect(x: 0, y: 0, width: UIScreen.mainScreen().bounds.size.width, height: UIApplication.sharedApplication().statusBarFrame.size.height)
        statusView.backgroundColor = UIColor.whiteColor()
        app.window?.addSubview(statusView)

        if let data = NSUserDefaults.standardUserDefaults().objectForKey("account") as? NSData {
            account = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! Account
        }

        self.refreshControl = UIRefreshControl()
        self.refreshControl?.hidden = true
        self.refreshControl!.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("applicationDidEnterBackground:"), name:UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("applicationDidBecomeActive:"), name:UIApplicationDidBecomeActiveNotification, object: nil)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        refresh(self)
    }

    func applicationDidEnterBackground(sender: AnyObject) {
        app.credentials = nil
        tableView.reloadData()
        backgrounded = true
    }

    func applicationDidBecomeActive(sender: AnyObject) {
        if backgrounded {
            refresh(self)
            backgrounded = false
        }
    }

    func refresh(sender: AnyObject) {
        struct Status { static var refreshing = false }

        if Status.refreshing {
            return
        }

        Status.refreshing = true

        if app.credentials == nil {
            let err: OSStatus
            (app.credentials, err) = Credentials.loadFromKeyChain()
            if err == errSecItemNotFound {
                self.performSegueWithIdentifier("link", sender: self)
            }
        }

        if let _ = app.credentials {
                app.ofx.getAccount(app.credentials!) { account in
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
                        
                        self.refreshControl?.endRefreshing()
                    }
                }

                Status.refreshing = false
            }
        }
        else {
            Status.refreshing = false
        }
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

        var ratios: [ChartDataEntry] = []
        var names: [String] = []
        var colors: [UIColor] = []

        for (index, position) in account.positions.enumerate() {
            let ratio = (position.price * Double(position.quantity)) / account.value
            names.append( ratio > 0.1 ? position.symbol : "")
            ratios.append(ChartDataEntry(value: ratio, xIndex: index))
            colors.append(position.category.color)
        }

        let pieChartDataSet = PieChartDataSet(yVals: ratios, label: "")
        pieChartDataSet.colors = colors
        pieChartDataSet.sliceSpace = 1
        pieChartDataSet.valueTextColor = UIColor.whiteColor()
        pieChartDataSet.drawValuesEnabled = false
        pieChartDataSet.selectionShift = 5

        let pieChartData = PieChartData(xVals: names, dataSet: pieChartDataSet)
        chartView.data = pieChartData
    }

}

extension Double {
    var currency: String {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
        formatter.locale = NSLocale.currentLocale()
        return formatter.stringFromNumber(self ?? 0) ?? "-"
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

        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("PortfolioCell")! as UITableViewCell!

            let valueField = cell.contentView.viewWithTag(21) as! UITextField
            let gainField = cell.contentView.viewWithTag(22) as! UITextField

            if let _ = app.credentials {
                valueField.text = account.value.currency

                gainField.text = account.gain != nil ? "\(account.gain?.currency) Today" : "-"
                if account.gain < 0 {
                    gainField.textColor = UIColor(red: CGFloat(255.0/255), green: CGFloat(47.0/255), blue: CGFloat(115.0/255), alpha: 1)
                }
                else {
                    gainField.textColor = UIColor(red: CGFloat(77.0/255), green: CGFloat(195.0/255), blue: CGFloat(33.0/255), alpha: 1)
                }
            }
            else {
                valueField.text = "Pull to Refresh"

                gainField.textColor = UIColor.blackColor()
                gainField.text = "Sensitive data requires identification"
            }

            createChart(cell.contentView.viewWithTag(23) as! PieChartView)

            return cell
        }

        let cell = tableView.dequeueReusableCellWithIdentifier("PositionCell")! as UITableViewCell!

        let position = account.positions[indexPath.row]

        let symbolField = cell.contentView.viewWithTag(1) as! UITextField
        symbolField.text = position.symbol

        let descriptionField = cell.contentView.viewWithTag(2) as! UITextField
        descriptionField.text = position.descr ?? "No description"

        let valueField = cell.contentView.viewWithTag(3) as! UITextField
        valueField.text = (position.price * Double(position.quantity)).currency

        var lineView = cell.contentView.viewWithTag(4)
        if lineView == nil {
            lineView = UIView()
            lineView!.frame = CGRect(x: 0, y: 0, width: 5, height: 50)
            lineView!.tag = 4
            cell.contentView.addSubview(lineView!)
        }
        lineView!.backgroundColor = position.category.color

//        var ratioView = cell.contentView.viewWithTag(5)
//        if ratioView == nil {
//            ratioView = UIView()
//            ratioView!.tag = 5
//            ratioView!.alpha = 0.05
//            cell.contentView.addSubview(ratioView!)
//        }
//        let ratioWidth = Double(cell.contentView.frame.width) * position.price * Double(position.quantity) / account.value
//        ratioView!.frame = CGRect(x: 0, y: 0, width: ratioWidth, height:50)
//        ratioView!.backgroundColor = position.category.color

        return cell
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return 2
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        if indexPath.section == 0 {
            return 300
        }

        return 50
    }

}

