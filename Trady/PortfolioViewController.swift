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
    var blurView: UIView?

    var expandedIndexPath: NSIndexPath?

    var app: AppDelegate {
        return (UIApplication.sharedApplication().delegate as! AppDelegate)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0)

        self.refreshControl = UIRefreshControl()
        self.refreshControl?.hidden = true
        self.refreshControl!.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("applicationDidEnterBackground:"), name:UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("applicationDidBecomeActive:"), name:UIApplicationDidBecomeActiveNotification, object: nil)

        if let data = NSUserDefaults.standardUserDefaults().objectForKey("account") as? NSData {
            account = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! Account
        }
        else {
            blurView = UIVisualEffectView(effect: UIBlurEffect(style: .ExtraLight))
            blurView!.frame = app.window!.frame
            app.window!.addSubview(blurView!)
        }
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

        self.refreshControl?.endRefreshing()

        if Status.refreshing {
            return
        }

        Status.refreshing = true

        self.app.status.displayNotificationWithMessage("Syncing account...") {}

        var credentials = app.credentials

        if app.credentials == nil {
            let err: OSStatus
            (credentials, err) = Credentials.loadFromKeyChain()
            if err == errSecItemNotFound {
                self.performSegueWithIdentifier("link", sender: self)
            }
        }

        let completion = {
            Status.refreshing = false
            dispatch_async(dispatch_get_main_queue()) {
                self.app.status.dismissNotification()
                self.tableView.reloadData()
            }
        }

        if let credentials = credentials {
            app.ofx.getAccount(credentials) { account in
                if let account = account {
                    self.account = account

                    self.blurView?.removeFromSuperview()

                    YahooClient.updateAccount(self.account) {
                        completion()
                        account.save()
                    }
                }
                else {
                    completion()
                    self.app.status.displayNotificationWithMessage("Try again later", forDuration: 5)
                }

                self.app.credentials = credentials
            }
        }
        else {
            completion()
        }
    }

    override func scrollViewDidScroll(scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y + 20
        let statusBarWindow = UIApplication.sharedApplication().valueForKey("statusBarWindow") as! UIWindow
        statusBarWindow.frame = CGRect(x: 0, y: offset > 0 ? -offset : 0, width: statusBarWindow.frame.size.width, height: statusBarWindow.frame.size.height)
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
            let cell = tableView.dequeueReusableCellWithIdentifier("SummaryCell")! as! SummaryCell
            cell.portfolioController = self
            cell.update(account)
            return cell
        }

        let cell = tableView.dequeueReusableCellWithIdentifier("PositionCell")! as! PositionCell
        let position = account.positions[indexPath.row]
        cell.update(account, position: position)
        return cell
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return 2
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        if indexPath.section == 0 {
            return 305
        }

        if indexPath == expandedIndexPath {
            return 200
        }

        return 55
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        tableView.beginUpdates()

        if indexPath.section == 0 || indexPath == expandedIndexPath {
            expandedIndexPath = nil
        }
        else {
            expandedIndexPath = indexPath
        }

        tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Fade)

        tableView.endUpdates()

    }

}
