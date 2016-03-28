//
//  ViewController.swift
//  Trady
//
//  Created by Floris Chabert on 2/4/16.
//  Copyright © 2016 Floris Chabert. All rights reserved.
//`

import UIKit
import Charts
import SCLAlertView

class PortfolioViewController: UITableViewController {

    static let blue = UIColor(red: CGFloat(0.0/255), green: CGFloat(178.0/255), blue: CGFloat(220.0/255), alpha: 1)
    static let red = UIColor(red: CGFloat(255.0/255), green: CGFloat(47.0/255), blue: CGFloat(115.0/255), alpha: 1)
    static let brown = UIColor(red: CGFloat(150.0/255), green: CGFloat(140.0/255), blue: CGFloat(138.0/255), alpha: 1)
    static let yellow = UIColor(red: CGFloat(255.0/255), green: CGFloat(148.0/255), blue: CGFloat(0.0/255), alpha: 1)
    static let green = UIColor(red: CGFloat(77.0/255), green: CGFloat(195.0/255), blue: CGFloat(33.0/255), alpha: 1)
    static let colors = [blue, red, brown, yellow, green]

    @IBOutlet weak var searchBar: UISearchBar!
    var searchResults: [YahooClient.SearchResult]?

    var account: Account?

    var extraSymbols = ["AAPL", "GOOG", "QQQ", "SPY", "TSLA", "YHOO"]

    var backgrounded = false

    var lastUpdated: NSDate?

    var expandedIndexPath: NSIndexPath?

    var timer: dispatch_source_t?

    var hideStatusBar = false

    var summaryPie = false

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
                change = account?.change {
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

        searchBar.delegate = self

        tableView.allowsSelectionDuringEditing = false

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(PortfolioViewController.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UIApplicationDelegate.applicationDidEnterBackground(_:)), name:UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UIApplicationDelegate.applicationDidBecomeActive(_:)), name:UIApplicationDidBecomeActiveNotification, object: nil)

        if let data = NSUserDefaults.standardUserDefaults().objectForKey("account") as? NSData {
            account = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? Account
        }

        if let data = NSUserDefaults.standardUserDefaults().objectForKey("extraSymbols") as? NSData {
            extraSymbols = (NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [String]) ?? []
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

        (self.app.credentials, _) = Credentials.loadFromKeyChain()

        tableView.setContentOffset(CGPointMake(0, -20), animated: false)

        refresh(self)
    }

    func applicationDidEnterBackground(sender: AnyObject) {
        app.credentials = nil
        tableView.reloadData()
        backgrounded = true
        dispatch_suspend(timer!)
        account?.save()
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

            if self.app.credentials != nil && interval > 3 * 3600 {
                updateOFX = true
            }

            dispatch_sync(dispatch_get_main_queue()) {
                self.animateTitle("Refreshing...")
            }

            let completion = {
                dispatch_sync(dispatch_get_main_queue()) {
                    self.refreshControl?.endRefreshing()
                    self.tableView.reloadSections(NSIndexSet(index: Section.Summary.rawValue), withRowAnimation: .Automatic)
                    self.tableView.reloadData()
                    self.animateTitle()
                }
            }

            if let _ = self.app.credentials {
                self.lastUpdated = NSDate()
            }

            let sem = dispatch_semaphore_create(0)

            if updateOFX {
                self.app.ofx.getAccount(self.app.credentials!) { account in

                    if let account = account {
                        self.account = account
                        account.save()

                        for position in account.positions {
                            if let index = self.extraSymbols.indexOf(position.symbol) {
                                self.extraSymbols.removeAtIndex(index)
                            }
                        }

                        let defaults = NSUserDefaults.standardUserDefaults()
                        let data = NSKeyedArchiver.archivedDataWithRootObject(self.extraSymbols) as NSData
                        defaults.removeObjectForKey("extraSymbols")
                        defaults.setObject(data, forKey: "extraSymbols")
                    }

                    dispatch_semaphore_signal(sem)
                }
                dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
            }

            if updateHistorical {
                YahooClient.historical(self.account, extraSymbols: self.extraSymbols) {
                    dispatch_semaphore_signal(sem)
                }
                dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
            }

            YahooClient.updateAccount(self.account, extraSymbols: self.extraSymbols) {
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

extension PortfolioViewController: UISearchBarDelegate {

    func dismissSearch() {
        self.searchResults = nil
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
            self.searchBar.endEditing(true)
            self.searchBar.text = ""
            self.searchBar.resignFirstResponder()
            self.tableView.setContentOffset(CGPointMake(0, -20), animated: true)
        }
    }

    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.characters.count == 0 {
            dismissSearch()
            return
        }

        YahooClient.search(searchText, completion: { results in
            self.searchResults = results
            dispatch_sync(dispatch_get_main_queue()) {
                self.tableView.reloadData()
            }
        })
    }

}

extension PortfolioViewController {

    enum Section: Int {
        case Summary = 0, Position = 1, Cash = 2, ExtraSymbol = 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if let searchResults = searchResults {
            return searchResults.count
        }

        if section == Section.Summary.rawValue {
            return 1
        }

        if section == Section.Cash.rawValue {
            return account == nil ? 0 : 1
        }

        if section == Section.Position.rawValue {
            return account?.positions.count ?? 0
        }

        return extraSymbols.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        if let searchResults = searchResults {
            let cell = tableView.dequeueReusableCellWithIdentifier("SearchCell")!
            cell.textLabel!.text = searchResults[indexPath.row].symbol
            cell.detailTextLabel!.text = searchResults[indexPath.row].name
            return cell
        }

        if indexPath.section == Section.Summary.rawValue {
            let cell = tableView.dequeueReusableCellWithIdentifier("SummaryCell")! as! SummaryCell
            cell.portfolioController = self
            cell.update(account)
            return cell
        }

        let cell = tableView.dequeueReusableCellWithIdentifier("PositionCell")! as! PositionCell
        cell.portfolioController = self
        cell.expanded = indexPath == expandedIndexPath

        var position: Position?
        if indexPath.section == Section.Position.rawValue {
            position = account?.positions[indexPath.row]
        }

        var symbol: String?
        if indexPath.section == Section.ExtraSymbol.rawValue {
            symbol = extraSymbols[indexPath.row]
        }

        cell.update(account, position: position, extraSymbol: symbol, index: indexPath.row)
        return cell
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        if let _ = searchResults {
            return 1
        }
        
        return 4
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        if let _ = searchResults {
            return 55
        }

        if indexPath.section == Section.Summary.rawValue {
            if let _ = app.credentials, _ = account {
                return 270
            }
            return 75
        }

        if indexPath.section == Section.Cash.rawValue {
            return 35
        }

        var shouldExpand = true
        if indexPath.section == Section.Position.rawValue {
            let category = self.account?.positions[indexPath.row].category
            shouldExpand = category == .Equity || category == .Fund
        }

        if indexPath == expandedIndexPath && shouldExpand {
            return 230
        }

        return 55
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        if let searchResults = searchResults {
            let result = searchResults[indexPath.row]
            var shouldAdd = true

            if let account = account {
                for position in account.positions {
                    if result.symbol == position.symbol {
                        shouldAdd = false
                        break
                    }
                }
            }

            for extraSymbol in extraSymbols {
                if result.symbol == extraSymbol {
                    shouldAdd = false
                    break
                }
            }

            if shouldAdd {
                extraSymbols.append(result.symbol)
                extraSymbols.sortInPlace()

                let defaults = NSUserDefaults.standardUserDefaults()
                let data = NSKeyedArchiver.archivedDataWithRootObject(self.extraSymbols) as NSData
                defaults.removeObjectForKey("extraSymbols")
                defaults.setObject(data, forKey: "extraSymbols")
            }

            dismissSearch()
            refresh(self)

            return
        }

        if indexPath.section == Section.Summary.rawValue {
            if self.app.credentials == nil {
                var err: OSStatus
                (self.app.credentials, err) = Credentials.loadFromKeyChain()
                if err == errSecItemNotFound {
                    self.presentViewController(LoginController(), animated: true) {}
                    return
                }
            }
            else {
                let alert = UIAlertController(title: "Accound synced", message: "Trady in synced with your E*Trade account \(app.credentials!.account).", preferredStyle: .Alert)
                let unlinkAction = UIAlertAction(title: "Unlink", style: .Destructive) { (action) in
                    self.app.credentials = nil
                    Credentials.deleteFromKeyChain()
                    self.account = nil
                    NSUserDefaults.standardUserDefaults().removeObjectForKey("account")

                    dispatch_async(dispatch_get_main_queue()) {
                        self.tableView.reloadData()
                    }
                }
                alert.addAction(unlinkAction)
                let okAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
                alert.addAction(okAction)
                self.presentViewController(alert, animated: true) {}
            }
        }

        tableView.beginUpdates()

        expandedIndexPath = indexPath == expandedIndexPath ? nil : indexPath
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)

        tableView.endUpdates()

        if let expandedIndexPath = expandedIndexPath {
            let cellRect = tableView.rectForRowAtIndexPath(expandedIndexPath)
            let completelyVisible = tableView.bounds.contains(cellRect)

            if !completelyVisible {
                tableView.scrollToRowAtIndexPath(expandedIndexPath, atScrollPosition: .Bottom, animated: true)
            }
        }
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {

        return indexPath.section == Section.ExtraSymbol.rawValue
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {

        if editingStyle != .Delete {
            return
        }

        extraSymbols.removeAtIndex(indexPath.row)
        let defaults = NSUserDefaults.standardUserDefaults()
        let data = NSKeyedArchiver.archivedDataWithRootObject(self.extraSymbols) as NSData
        defaults.removeObjectForKey("extraSymbols")
        defaults.setObject(data, forKey: "extraSymbols")

        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }

}

extension PortfolioViewController {

    func LoginController() -> UIAlertController {
        let alertController = UIAlertController(title: "Link account", message: "Sync with your E*Trade account.\nTrady can only see your trading portfolio.", preferredStyle: .Alert)

        let loginAction = UIAlertAction(title: "Login", style: .Default) { (_) in
            let loginTextField = alertController.textFields![0] as UITextField
            let passwordTextField = alertController.textFields![1] as UITextField

            self.app.ofx.login(loginTextField.text!, passwordTextField.text!) { credentials in
                if let credentials = credentials {
                    self.app.credentials = credentials
                    self.app.credentials?.saveToKeyChain()
                    self.lastUpdated = nil
                    self.refresh(self)
                }
                else {
                    dispatch_sync(dispatch_get_main_queue()) {
                        let alertController = UIAlertController(title: "Login failed", message: "Please check your credentials and try again.", preferredStyle: .Alert)
                        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
                        alertController.addAction(OKAction)
                        self.presentViewController(alertController, animated: true) {}
                    }
                }
            }
        }
        loginAction.enabled = false

        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Username"

            NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue()) { (notification) in
                loginAction.enabled = textField.text != ""
            }
        }

        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Password"
            textField.secureTextEntry = true
        }

        alertController.addAction(loginAction)

        return alertController
    }

}