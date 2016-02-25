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
    let etrade: ETradeClient = ETradeClient()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        return true
    }

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        if (url.host == "oauth-callback") {
            etrade.deliverUrl(url)
        }
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
    }

    func applicationDidEnterBackground(application: UIApplication) {
        let lauchStoryboard = UIStoryboard(name: "LaunchScreen", bundle: nil)
        let lauchController = lauchStoryboard.instantiateInitialViewController()
        self.window?.rootViewController?.presentViewController(lauchController!, animated: false, completion: nil)
    }

    func applicationWillEnterForeground(application: UIApplication) {
        self.window?.rootViewController?.dismissViewControllerAnimated(false, completion: nil)
    }

    func applicationDidBecomeActive(application: UIApplication) {
    }

    func applicationWillTerminate(application: UIApplication) {
    }

}

extension AppDelegate {

    func saveCredentials() {

        let accessControlError:UnsafeMutablePointer<Unmanaged<CFError>?> = nil
        let accessControlRef = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            SecAccessControlCreateFlags.UserPresence,
            accessControlError
        )

        let string = "\(etrade.oauth.token!) \(etrade.oauth.tokenSecret!)"
        let data: NSData = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!

        let query: [NSString : AnyObject] = [
            kSecClass : kSecClassGenericPassword,
            kSecAttrAccessControl: accessControlRef!,
            kSecAttrService : "Trady",
            kSecValueData : data
        ]

        SecItemDelete(query)
        SecItemAdd(query, nil)
    }

    func loadCredentials() -> Bool {

        let query: [NSString : AnyObject] = [
            kSecClass : kSecClassGenericPassword,
            kSecAttrService : "Trady",
            kSecReturnData: kCFBooleanTrue,
            kSecMatchLimit : kSecMatchLimitOne,
            kSecUseOperationPrompt: "Identification required to access your portfolio."
        ]

        var result : AnyObject?
        let err = SecItemCopyMatching(query, &result)

        if err == errSecSuccess {

            if let data = result as? NSData,
                let tokenString = NSString(data:data, encoding:NSUTF8StringEncoding) as? String {

                    let tokens = tokenString.componentsSeparatedByString(" ")
                    if tokens.count == 2 {
                        etrade.oauth.token = tokens[0]
                        etrade.oauth.tokenSecret = tokens[1]

                        return true
                    }
            }
        }

        return false
    }

}
