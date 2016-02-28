//
//  LinkViewController.swift
//  Trady
//
//  Created by Floris Chabert on 2/23/16.
//  Copyright © 2016 Floris Chabert. All rights reserved.
//

import UIKit

class LinkViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var link: UIButton!

    var app: AppDelegate {
        return (UIApplication.sharedApplication().delegate as! AppDelegate)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        username.delegate = self
        password.delegate = self

        username.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func setWaitState(isWaiting: Bool = true) {
        username.enabled = !isWaiting
        password.enabled = !isWaiting
        username.userInteractionEnabled = !isWaiting
        password.userInteractionEnabled = !isWaiting
        UIApplication.sharedApplication().networkActivityIndicatorVisible = isWaiting
    }

    func linkAccount(sender: AnyObject) {
        setWaitState()

        app.ofx.login(username.text!, password.text!) { credentials in
            if let credentials = credentials {
                self.app.credentials = credentials
                self.app.credentials?.saveToKeyChain()

                dispatch_async(dispatch_get_main_queue()) {
                    self.setWaitState(false)
                    self.dismissViewControllerAnimated(true) {}
                }
            }
            else {
                dispatch_async(dispatch_get_main_queue()) {
                    self.setWaitState(false)

                    let alert = UIAlertController(title: "Login failed", message: "Please verify your username and password and retry.", preferredStyle: UIAlertControllerStyle.Alert)
                    let alertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (UIAlertAction) -> Void in }
                    alert.addAction(alertAction)
                    self.presentViewController(alert, animated: true) {}
                }
            }
        }
    }

    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        return true
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        if textField == username {
            password.becomeFirstResponder()
        }
        else {
            linkAccount(self)
        }

        return true
    }

}

