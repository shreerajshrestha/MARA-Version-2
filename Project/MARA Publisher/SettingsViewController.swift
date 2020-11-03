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
    
    private var xmlParser: NSXMLParser = NSXMLParser(contentsOfURL: NSURL(string:"http://social.rollins.edu/mara/settings.xml"))!
    private var settings = [[String:String]()]
    private var setting = [String:String]()
    private var elementString = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        xmlParser.delegate = self
        xmlParser.parse()
        
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
        
        var error: NSError?
        if let ftpPassword = SSKeychain.passwordForService("mara.ftp", account: defaults.objectForKey("ftpUsername") as? String, error: &error) {
            ftpPasswordTextField.text = ftpPassword
        }
        if let err = error {
            println("SSKeychain setPassword error: \(err.localizedDescription)")
        }
        
        if let blogUrl = defaults.objectForKey("blogUrl") as? String {
            blogUrlTextField.text = blogUrl
        }
        if defaults.boolForKey("useHttpMask") {
            httpMaskSwitch.on = true
        }
        else {
            httpMaskSwitch.on = false
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
            httpMaskTextField.enabled = false
        }
    }
    
    func saveUserSettings() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(ftpUrlTextField.text, forKey: "ftpUrl")
        defaults.setObject(ftpUsernameTextField.text, forKey: "ftpUsername")
        defaults.setObject(blogUrlTextField.text, forKey: "blogUrl")
        defaults.setBool(httpMaskSwitch.on == true, forKey: "useHttpMask")
        defaults.setObject(httpMaskTextField.text, forKey: "httpMask")
        
        var error: NSError?
        SSKeychain.setPassword(ftpPasswordTextField.text, forService: "mara.ftp", account: defaults.objectForKey("ftpUsername") as! String, error: &error)
        if let err = error {
            println("SSKeychain setPassword error: \(err.localizedDescription)")
        }
    }
    
    @IBAction func backButtonPressed(sender: UIBarButtonItem) {
        saveUserSettings()
        self.navigationController?.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func internetAvailable() -> Bool {
        let reachability: Reachability = Reachability.reachabilityForInternetConnection()
        let connectivity: Int = reachability.currentReachabilityStatus().value
        if connectivity == 1 {
            return true
        }
        else {
            return false
        }
    }
    
    func importSettingsAtIndex(index: Int) {
        ftpUrlTextField.text = settings[index]["ftpUrl"]
        ftpUsernameTextField.text = settings[index]["ftpUsername"]
        ftpPasswordTextField.text = ""
        blogUrlTextField.text = settings[index]["blogUrl"]
        httpMaskSwitch.on = settings[index]["useHttpMask"] == "1"
        httpMaskTextField.text = httpMaskSwitch.on ? settings[index]["httpMask"] : ""
    }
    
    @IBAction func importButtonPressed(sender: UIBarButtonItem) {
        
        if !internetAvailable() {
            let alert = UIAlertController(title: "No Internet!", message: "Importing settings requires a working internet connection.", preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "OK", style: .Default) { (action) in
            }
            alert.addAction(okAction)
        }
        else {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
            
            for i in 1...count(settings)-1 {
                let action = UIAlertAction(title: settings[i]["domain"]!, style: .Default) { (action) in
                    self.importSettingsAtIndex(i)
                }
                alert.addAction(action)
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            alert.addAction(cancelAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
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
        return false
    }
    
    // MARK: - NSXMLParser Delegate
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [NSObject : AnyObject]) {
        
        if elementName == "domain" {
            setting = [String:String]()
            setting["domain"] = attributeDict["category"] as? String
        }
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String?) {
        elementString = string!
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "domain" {
            settings.append(setting)
        }
        setting[elementName] = elementString
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
    
}
