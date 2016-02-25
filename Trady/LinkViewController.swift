//
//  LinkViewController.swift
//  Trady
//
//  Created by Floris Chabert on 2/23/16.
//  Copyright © 2016 Floris Chabert. All rights reserved.
//

import UIKit

class LinkViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func tap(sender: AnyObject) {
        let app = UIApplication.sharedApplication().delegate as! AppDelegate

        UIApplication.sharedApplication().networkActivityIndicatorVisible = true

        app.etrade.authorize() {
            dispatch_async(dispatch_get_main_queue(), {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                self.navigationController?.popViewControllerAnimated(false)
            })
        }
    }
    
}

