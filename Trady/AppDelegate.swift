//
//  AppDelegate.swift
//  Trady
//
//  Created by Floris Chabert on 2/4/16.
//  Copyright © 2016 Floris Chabert. All rights reserved.
//

import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var credentials: Credentials?
    let ofx = OFXClient(url: NSURL(string: "https://ofx.etrade.com/cgi-ofx/etradeofx")!)

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        credentials = Credentials.loadFromKeyChain()

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
    }

    func applicationDidEnterBackground(application: UIApplication) {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        blurView.frame = (self.window?.frame)!
        blurView.tag = 42;
        self.window?.addSubview(blurView)
    }

    func applicationWillEnterForeground(application: UIApplication) {
        credentials = Credentials.loadFromKeyChain()

        if let view = self.window?.viewWithTag(42) {
            view.alpha = 0
            view.removeFromSuperview()
        }
    }

    func applicationDidBecomeActive(application: UIApplication) {
    }

    func applicationWillTerminate(application: UIApplication) {
    }

}
