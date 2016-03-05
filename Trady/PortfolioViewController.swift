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

    var account = Account("", value: 0, cash: 0, positions: [
        Position("SPY", category: Category.Equity, price: 100, quantity: 1),
        Position("QQQ", category: Category.Equity, price: 100, quantity: 1),
        Position("AAPL", category: Category.Equity, price: 100, quantity: 1),
        Position("GOOG", category: Category.Equity, price: 100, quantity: 1),
        Position("TSLA", category: Category.Equity, price: 100, quantity: 1),
    ])

    var backgrounded = false

    var expandedIndexPath: NSIndexPath?

    var timer: dispatch_source_t?

    var hideStatusBar = false

    var app: AppDelegate {
        return (UIApplication.sharedApplication().delegate as! AppDelegate)
    }

    func setupTableView() {
        refreshControl = UIRefreshControl()
        refreshControl?.hidden = true
        refreshControl?.backgroundColor = UIColor(red: 0.99, green: 0.99, blue: 0.99, alpha: 1)
        refreshControl?.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)

        let px = 1 / UIScreen.mainScreen().scale
        let frame = CGRectMake(0, 0, self.tableView.frame.size.width, px)
        let line: UIView = UIView(frame: frame)
        tableView.tableHeaderView = line
        line.backgroundColor = tableView.separatorColor

        tableView.contentInset = UIEdgeInsetsMake(-1, 0, 0, 0);
    }

    func rotateTitle(duration: Double = 1) {
        if view.layer.animationForKey("io.trady.refreshanimation") == nil {
            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")

            rotationAnimation.fromValue = 0.0
            rotationAnimation.toValue = Float(M_PI * 2.0)
            rotationAnimation.duration = duration
            rotationAnimation.repeatCount = Float.infinity

            navigationItem.titleView?.layer.addAnimation(rotationAnimation, forKey: "io.trady.refreshanimation")
        }
    }

    func stopRotatingTitle() {
        if navigationItem.titleView?.layer.animationForKey("io.trady.refreshanimation") != nil {
            navigationItem.titleView?.layer.removeAnimationForKey("io.trady.refreshanimation")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let buttonView = UIView(frame: CGRectMake(0, 0, 40, 40))
        let button = UIButton(type: .Custom)
        button.setBackgroundImage(UIImage(named: "TopImage"), forState: .Normal)
        button.adjustsImageWhenHighlighted = false
        button.frame = CGRectMake(0, 0, 40, 40)
        button.addTarget(self, action: "link:", forControlEvents: .TouchUpInside)
        buttonView.addSubview(button)
        navigationItem.titleView = buttonView

//        rotateTitle()

//        navigationController?.hidesBarsOnSwipe = true

        setupTableView()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("applicationDidEnterBackground:"), name:UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("applicationDidBecomeActive:"), name:UIApplicationDidBecomeActiveNotification, object: nil)

        if let data = NSUserDefaults.standardUserDefaults().objectForKey("account") as? NSData {
            account = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! Account
        }

        let updateRate = 15
        timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, DISPATCH_TARGET_QUEUE_DEFAULT);
        dispatch_source_set_timer(timer!, dispatch_time(DISPATCH_TIME_NOW, Int64(updateRate) * Int64(NSEC_PER_SEC)), UInt64(updateRate) * NSEC_PER_SEC, NSEC_PER_SEC)
        dispatch_source_set_event_handler(timer!) {
            self.refreshQuotes()
        }
        dispatch_resume(timer!)

        self.refreshQuotes()

        YahooClient.historical(account)
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
    }

    func applicationDidBecomeActive(sender: AnyObject) {
        if backgrounded {
            refresh(self)
            backgrounded = false
            dispatch_resume(timer!)
        }
    }

    func link(sender: AnyObject) {
        self.performSegueWithIdentifier("link", sender: self)
    }

    func refresh(sender: AnyObject) {
        struct Status { static var refreshing = false }

        if Status.refreshing {
            return
        }

        Status.refreshing = true

        var credentials = app.credentials

        if app.credentials == nil {
            let err: OSStatus
            (credentials, err) = Credentials.loadFromKeyChain()
            if err == errSecItemNotFound {
                self.performSegueWithIdentifier("link", sender: self)
                Status.refreshing = false
                return
            }
        }

        let completion = {
            Status.refreshing = false
            dispatch_async(dispatch_get_main_queue()) {
                self.refreshControl?.endRefreshing()
                self.tableView.reloadData()
            }
        }

        if let credentials = credentials {
            app.ofx.getAccount(credentials) { account in
                if let account = account {
                    self.account = account
                }

                self.refreshQuotes() {
                    completion()
                }

                self.app.credentials = credentials
            }
        }
        else {
            self.refreshQuotes() {
                completion()
            }
        }
    }

    func refreshQuotes(completion: () -> Void = {}) {
        YahooClient.updateAccount(self.account) {
            completion()
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
            }
            self.account.save()
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

        if section == 0 {
            return 1
        }

        var count = 0
        account.sync {
            count = self.account.positions.count
        }

        return count
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

        var position: Position?
        account.sync {
            position = self.account.positions[indexPath.row]
        }
        cell.update(account, position: position!)
        return cell
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return 2
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        if indexPath.section == 0 {
            return 305
        }

        var category: Category?
        account.sync {
            category = self.account.positions[indexPath.row].category
        }

        let shouldExpand = category == Category.Equity || category == Category.Fund
        if indexPath == expandedIndexPath && shouldExpand {
            return 200
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
    }

}
