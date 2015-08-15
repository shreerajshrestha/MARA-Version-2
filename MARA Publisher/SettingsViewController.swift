//
//  SettingsViewController.swift
//  MARA Publisher
//
//  Created by Shree Raj Shrestha on 8/13/15.
//  Copyright (c) 2015 Shree Raj Shrestha. All rights reserved.
//

import UIKit
import Foundation

private var kAssociationKeyNextField: UInt8 = 0

extension UITextField {
    var nextField: UITextField? {
        get {
            return objc_getAssociatedObject(self, &kAssociationKeyNextField) as? UITextField
        }
        set(newField) {
            objc_setAssociatedObject(self, &kAssociationKeyNextField, newField, UInt(OBJC_ASSOCIATION_RETAIN))
        }
    }
}

class SettingsViewController: UITableViewController, UITextFieldDelegate, NSXMLParserDelegate {
    
    @IBOutlet weak var ftpUrlTextField: UITextField!
    @IBOutlet weak var ftpUsernameTextField: UITextField!
    @IBOutlet weak var ftpPasswordTextField: UITextField!
    @IBOutlet weak var httpMaskSwitch: UISwitch!
    @IBOutlet weak var httpMaskTextField: UITextField!
    @IBOutlet weak var blogUrlTextField: UITextField!
    
    var parser = NSXMLParser()
    var ftpUrl = NSString()
    var ftpUsername = NSString()
    var blogUrl = NSString()
    var useHttpMask = Int()
    var httpMask = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        httpMaskSwitch.addTarget(self, action: Selector("switchStateChanged:"), forControlEvents: UIControlEvents.ValueChanged)
        
        ftpUrlTextField.delegate = self
        ftpUrlTextField.nextField = ftpUsernameTextField
        ftpUsernameTextField.delegate = self
        ftpUsernameTextField.nextField = ftpPasswordTextField
        ftpPasswordTextField.delegate = self
        ftpPasswordTextField.nextField = blogUrlTextField
        blogUrlTextField.delegate = self
        blogUrlTextField.nextField = httpMaskTextField
        httpMaskTextField.delegate = self
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if let ftpUrl = defaults.objectForKey("ftpUrl") as? String {
            ftpUrlTextField.text = ftpUrl
        }
        if let ftpUsername = defaults.objectForKey("ftpUsername") as? String {
            ftpUsernameTextField.text = ftpUsername
        }
        if let ftpPassword = defaults.objectForKey("ftpPassword") as? String {
            ftpPasswordTextField.text = ftpPassword
        }
        if let blogUrl = defaults.objectForKey("blogUrl") as? String {
            blogUrlTextField.text = blogUrl
        }
        if defaults.boolForKey("useHttpMask") {
            httpMaskSwitch.on = true
        }
        else {
            httpMaskSwitch.on = false
            httpMaskTextField.text = ""
            httpMaskTextField.enabled = false
        }
        if let httpMask = defaults.objectForKey("httpMask") as? String {
            httpMaskTextField.text = httpMask
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func switchStateChanged(maskSwitch: UISwitch) {
        if maskSwitch.on {
            httpMaskTextField.enabled = true
        }
        else {
            httpMaskTextField.text = ""
            httpMaskTextField.enabled = false
        }
    }
    
    @IBAction func backButtonPressed(sender: UIBarButtonItem) {
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(ftpUrlTextField.text, forKey: "ftpUrl")
        defaults.setObject(ftpUsernameTextField.text, forKey: "ftpUsername")
        defaults.setObject(ftpPasswordTextField.text, forKey: "ftpPassword")
        defaults.setObject(blogUrlTextField.text, forKey: "blogUrl")
        defaults.setBool(httpMaskSwitch.on == true, forKey: "useHttpMask")
        defaults.setObject(httpMaskTextField.text, forKey: "httpMask")
        
        self.navigationController?.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - UITextField Delegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let nextField = textField.nextField {
            if nextField.enabled {
                nextField.becomeFirstResponder()
            }
            else {
                textField.resignFirstResponder()
            }
        }
        else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    // MARK: - Table view data source
    
    /*
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
    
    // MARK: - NSXML Parse Delegate
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [NSObject : AnyObject]) {
        println(elementName)
        
    }
    
    
}
