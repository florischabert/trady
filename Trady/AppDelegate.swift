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
        return true
    }

}
