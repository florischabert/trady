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

    static let blue = UIColor(red: CGFloat(0.0/255), green: CGFloat(178.0/255), blue: CGFloat(220.0/255), alpha: 1)
    static let red = UIColor(red: CGFloat(255.0/255), green: CGFloat(47.0/255), blue: CGFloat(115.0/255), alpha: 1)
    static let brown = UIColor(red: CGFloat(150.0/255), green: CGFloat(140.0/255), blue: CGFloat(138.0/255), alpha: 1)
    static let yellow = UIColor(red: CGFloat(255.0/255), green: CGFloat(148.0/255), blue: CGFloat(0.0/255), alpha: 1)
    static let green = UIColor(red: CGFloat(77.0/255), green: CGFloat(195.0/255), blue: CGFloat(33.0/255), alpha: 1)
    static let colors = [blue, red, brown, yellow, green]

    var account = Account("", value: 0, cash: 0, positions: [
        Position("SPY", category: .Equity, price: 100, quantity: 1),
        Position("QQQ", category: .Equity, price: 100, quantity: 1),
        Position("AAPL", category: .Equity, price: 100, quantity: 1),
        Position("GOOG", category: .Equity, price: 100, quantity: 1),
        Position("TSLA", category: .Equity, price: 100, quantity: 1),
    ])

    var backgrounded = false

    var lastUpdated: NSDate?

    var expandedIndexPath: NSIndexPath?

    var timer: dispatch_source_t?

    var hideStatusBar = false

    var app: AppDelegate {
        return (UIApplication.sharedApplication().delegate as! AppDelegate)
    }

    func animateTitle(title: String? = nil) {

        var text: String
        if let title = title {
            text = title
        }
        else {
            text = "Portfolio"

            if let _ = app.credentials,
                change = account.change {
                    text += change >= 0 ? " ➚" : " ➘"
            }
        }

        let animation = CATransition()
        animation.duration = 0.2
        animation.type = kCATransitionFade;
        animation.timingFunction = CAMediaTimingFunction(name: "easeInEaseOut")
        navigationItem.titleView!.layer.addAnimation(animation, forKey:"changeTitle")

        (navigationItem.titleView as! UILabel).text = text;
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let titleLabelView = UILabel(frame:CGRectMake(0, 0, 100, 22))
        titleLabelView.backgroundColor = UIColor.clearColor()
        titleLabelView.textAlignment = .Center
        titleLabelView.textColor = UIColor.blackColor()
        titleLabelView.font = UIFont.boldSystemFontOfSize(16.0)
        titleLabelView.adjustsFontSizeToFitWidth = true
        titleLabelView.text = "Potfolio"
        navigationItem.titleView = titleLabelView;

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("applicationDidEnterBackground:"), name:UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("applicationDidBecomeActive:"), name:UIApplicationDidBecomeActiveNotification, object: nil)

        if let data = NSUserDefaults.standardUserDefaults().objectForKey("account") as? NSData {
            account = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! Account
        }

        let updateRate = 15
        timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, DISPATCH_TARGET_QUEUE_DEFAULT);
        dispatch_source_set_timer(timer!, dispatch_time(DISPATCH_TIME_NOW, Int64(updateRate) * Int64(NSEC_PER_SEC)), UInt64(updateRate) * NSEC_PER_SEC, NSEC_PER_SEC)
        dispatch_source_set_event_handler(timer!) {
            self.refresh(self)
        }
        dispatch_resume(timer!)

        YahooClient.loadFromDefaults()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        refresh(self)
    }

    func applicationDidEnterBackground(sender: AnyObject) {
        app.credentials = nil
        tableView.reloadData()
        backgrounded = true
        dispatch_suspend(timer!)
        account.save()
    }

    func applicationDidBecomeActive(sender: AnyObject) {
        if backgrounded {
            refresh(self)
            backgrounded = false
            dispatch_resume(timer!)
        }
    }

    func refresh(sender: AnyObject) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            var updateOFX = false
            var updateHistorical = false

            var interval: NSTimeInterval
            if let lastUpdated = self.lastUpdated {
               interval = NSDate().timeIntervalSinceDate(lastUpdated)
            }
            else {
                interval = NSDate.timeIntervalSinceReferenceDate()
            }

            if interval > 4 * 3600 {
                updateHistorical = true
            }
            if interval > 3 * 3600 {
                updateOFX = true
            }

            if self.app.credentials == nil {
                let err: OSStatus
                (self.app.credentials, err) = Credentials.loadFromKeyChain()
                if err == errSecItemNotFound {
                    dispatch_sync(dispatch_get_main_queue()) {
                        self.refreshControl?.endRefreshing()
                    }
                    self.performSegueWithIdentifier("link", sender: self)
                    return
                }
            }

            dispatch_sync(dispatch_get_main_queue()) {
                self.animateTitle("Refreshing...")
            }

            let completion = {
                dispatch_sync(dispatch_get_main_queue()) {
                    self.refreshControl?.endRefreshing()
                    self.tableView.reloadData()
                    self.animateTitle()
                }
            }

            self.lastUpdated = NSDate()

            let sem = dispatch_semaphore_create(0)

            if let credentials = self.app.credentials {

                if updateOFX {
                    self.app.ofx.getAccount(credentials) { account in
                        if let account = account {
                            self.account = account
                        }

                        dispatch_semaphore_signal(sem)
                    }
                    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
                }

                if updateHistorical {
                    YahooClient.historical(self.account) {
                        dispatch_semaphore_signal(sem)
                    }
                    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
                }
            }

            YahooClient.updateAccount(self.account) {
                dispatch_semaphore_signal(sem)
            }
            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)

            completion()
        }
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

        if section <= 1 {
            return 1
        }

        return self.account.positions.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("SummaryCell")! as! SummaryCell
            cell.portfolioController = self
            cell.update(account)
            return cell
        }

        let cell = tableView.dequeueReusableCellWithIdentifier("PositionCell")! as! PositionCell
        cell.portfolioController = self
        cell.expanded = indexPath == expandedIndexPath
        cell.update(account, index: (indexPath.section == 1) ? -1 : indexPath.row)
        return cell
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return 3
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        if indexPath.section == 0 {
            return 296
        }

        if indexPath.section == 1 {
            return 35
        }

        let category = self.account.positions[indexPath.row].category
        let shouldExpand = category == .Equity || category == .Fund
        if indexPath == expandedIndexPath && shouldExpand {
            return 230
        }

        return 55
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        if indexPath.section == 0 {
            return
        }

        tableView.beginUpdates()

        expandedIndexPath = indexPath == expandedIndexPath ? nil : indexPath
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)

        tableView.endUpdates()

        if let expandedIndexPath = expandedIndexPath {
            let cellRect = tableView.rectForRowAtIndexPath(expandedIndexPath)
            let completelyVisible = tableView.bounds.contains(cellRect)

            if !completelyVisible {
                tableView.scrollToRowAtIndexPath(expandedIndexPath, atScrollPosition: .Bottom, animated: true)
            }
        }
    }

}

