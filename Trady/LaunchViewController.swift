//
//  LaunchViewController.swift
//  Trady
//
//  Created by Floris Chabert on 2/23/16.
//  Copyright © 2016 Floris Chabert. All rights reserved.
//

import UIKit

class LaunchViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        if app.loadCredentials() {
            app.etrade.update {
                dispatch_async(dispatch_get_main_queue(), {
                    self.performSegueWithIdentifier("Portfolio", sender: self)
                })
            }
        }
        else {
            self.performSegueWithIdentifier("Link", sender: self)
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
}