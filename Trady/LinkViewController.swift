//
//  LinkViewController.swift
//  Trady
//
//  Created by Floris Chabert on 2/23/16.
//  Copyright © 2016 Floris Chabert. All rights reserved.
//

import UIKit

class LinkViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var text: UITextView!
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var unlinkButton: UIButton!
    @IBOutlet weak var account: UILabel!
    
    var app: AppDelegate {
        return (UIApplication.sharedApplication().delegate as! AppDelegate)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        username.delegate = self
        password.delegate = self
        
        update()
    }

    func update() {
        dispatch_async(dispatch_get_main_queue()) {
            self.unlinkButton.hidden = self.app.credentials == nil
            self.account.hidden = self.app.credentials == nil
            self.username.hidden = self.app.credentials != nil
            self.password.hidden = self.app.credentials != nil
            self.navigationItem.hidesBackButton = self.app.credentials == nil

            if let cred = self.app.credentials {
                self.account.text = "Currently linked with account \(cred.account)"
            }
            else {
                self.username.becomeFirstResponder()
            }
        }
    }

    @IBAction func unlink(sender: AnyObject) {
        app.credentials = nil
        Credentials.deleteFromKeyChain()
        update()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func done(sender: AnyObject) {
        if let _ = app.credentials {
            self.dismissViewControllerAnimated(true) {}
        }
        else {
            linkAccount(sender)
        }
    }

    func setWaitState(isWaiting: Bool = true) {
        username.enabled = !isWaiting
        password.enabled = !isWaiting
        username.userInteractionEnabled = !isWaiting
        password.userInteractionEnabled = !isWaiting
        UIApplication.sharedApplication().networkActivityIndicatorVisible = isWaiting
    }

    func linkAccount(sender: AnyObject) {
        if username.text!.isEmpty || password.text!.isEmpty {
            dispatch_async(dispatch_get_main_queue()) {
                self.setWaitState(false)
                let alertController = UIAlertController(title: "Login failed", message: "Please check your credentials and try again.", preferredStyle: .Alert)
                let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
                alertController.addAction(OKAction)
                self.presentViewController(alertController, animated: true) {}
            }
            return
        }

        setWaitState()

        app.ofx.login(username.text!, password.text!) { credentials in
            if let credentials = credentials {
                self.app.credentials = credentials
                self.app.credentials?.saveToKeyChain()

                dispatch_async(dispatch_get_main_queue()) {
                    self.setWaitState(false)
                    self.navigationController?.popViewControllerAnimated(true)
                }
            }
            else {
                dispatch_async(dispatch_get_main_queue()) {
                    self.setWaitState(false)
                    let alertController = UIAlertController(title: "Login failed", message: "Please check your credentials and try again.", preferredStyle: .Alert)
                    let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
                    alertController.addAction(OKAction)
                    self.presentViewController(alertController, animated: true) {}
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

