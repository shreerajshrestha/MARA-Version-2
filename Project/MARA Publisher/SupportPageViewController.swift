//
//  SupportPageViewController.swift
//  MARA Publisher
//
//  Created by Shree Raj Shrestha on 8/13/15.
//  Copyright (c) 2015 Shree Raj Shrestha. All rights reserved.
//

import UIKit
import WebKit

class SupportPageViewController: UIViewController, WKNavigationDelegate {
    
    
    @IBOutlet weak var progressView: UIProgressView!
    private var webView: WKWebView
    private var myContext = 0
    
    required init(coder aDecoder: NSCoder) {
        self.webView = WKWebView(frame: CGRectZero)
        super.init(coder: aDecoder)
        self.webView.navigationDelegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.insertSubview(webView, belowSubview: progressView)
        
        webView.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        let height = NSLayoutConstraint(item: webView, attribute: .Height, relatedBy: .Equal, toItem: view, attribute: .Height, multiplier: 1, constant: 0)
        let width = NSLayoutConstraint(item: webView, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 1, constant: 0)
        view.addConstraints([height, width])
        
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .New, context: &myContext)
        
        let url = NSURL(string:"http://social.rollins.edu/wpsites/mara/help-and-documentation/")!
        let request = NSURLRequest(URL:url)
        self.webView.loadRequest(request)
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        progressView.frame = CGRect(x:0, y: 0, width: size.width, height: 30)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == &myContext {
            progressView.hidden = webView.estimatedProgress == 1
            progressView.setProgress(Float(webView.estimatedProgress), animated: true)
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    deinit {
        webView.removeObserver(self, forKeyPath: "estimatedProgress", context: &myContext)
    }
    
    @IBAction func backButtonPressed(sender: UIBarButtonItem) {
        self.navigationController?.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        progressView.setProgress(0.0, animated: false)
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        let alert = UIAlertController(title: "Error Loading Page!", message: error.localizedDescription, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
