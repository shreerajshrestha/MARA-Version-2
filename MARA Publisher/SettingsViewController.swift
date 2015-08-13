//
//  SettingsViewController.swift
//  MARA Publisher
//
//  Created by Shree Raj Shrestha on 8/13/15.
//  Copyright (c) 2015 Shree Raj Shrestha. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

    
    @IBOutlet weak var ftpUrlTextField: UITextField!
    @IBOutlet weak var ftpUsernameTextField: UITextField!
    @IBOutlet weak var ftpPasswordTextField: UITextField!
    @IBOutlet weak var ftpMaskSwitch: UISwitch!
    @IBOutlet weak var ftpMaskTextField: UITextField!
    @IBOutlet weak var blogUrlTextField: UITextField!
    @IBOutlet weak var blogUserNameTextField: UITextField!
    @IBOutlet weak var blogPasswordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        /*
        let defaults = NSUserDefaults.standardUserDefaults()
        ftpUrlTextField.text = defaults.objectForKey("ftpUrl") as? String
        ftpUsernameTextField.text = defaults.objectForKey("ftpUsername") as? String
        ftpPasswordTextField.text = defaults.objectForKey("ftpPassword") as? String
        ftpMaskSwitch.on = defaults.boolForKey("ftpMaskOn")
        ftpMaskTextField.text = defaults.objectForKey("ftpMask") as? String
        blogUrlTextField.text = defaults.objectForKey("blogUrl") as? String
        blogUserNameTextField.text = defaults.objectForKey("blogUsername") as? String
        blogPasswordTextField.text = defaults.objectForKey("blogPassword") as? String
        
        if defaults.boolForKey("ftpMaskOn") {
            ftpMaskSwitch.on = true
        }*/
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backButtonPressed(sender: UIBarButtonItem) {
        
        /*
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(ftpUrlTextField.text, forKey: "ftpUrl")
        defaults.setObject(ftpUsernameTextField.text, forKey: "ftpUsername")
        defaults.setObject(ftpPasswordTextField.text, forKey: "ftpPassword")
        defaults.setBool(ftpMaskSwitch.on, forKey: "useFtpMask")
        defaults.setObject(ftpMaskTextField.text, forKey: "ftpMask")
        defaults.setObject(blogUrlTextField.text, forKey: "blogUrl")
        defaults.setObject(blogUserNameTextField.text, forKey: "blogUsername")
        defaults.setObject(blogPasswordTextField.text, forKey: "blogPassword")
        
        self.navigationController?.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        self.dismissViewControllerAnimated(true, completion: nil)
*/
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return 0
    }

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as! UITableViewCell

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
