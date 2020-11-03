//
//  SupportPageViewController.swift
//  MARA Publisher
//
//  Created by Shree Raj Shrestha on 8/13/15.
//  Copyright (c) 2015 Shree Raj Shrestha. All rights reserved.
//

import UIKit
import WebKit

protocol PublisherDelegate {
    func updatePublishStatus(isPublishing: Bool)
}

extension NSData {
    func toUTF8String() -> String {
        var hexString: String = ""
        let dataBytes =  UnsafePointer<CUnsignedChar>(self.bytes)
        for (var i: Int=0; i<self.length; ++i) {
            hexString = String(format: "%02X", dataBytes[i]) + hexString
        }
        hexString.removeRange(advance(hexString.startIndex,4)..<hexString.endIndex)
        return hexString
    }
}

class PublishViewController: UIViewController, WKNavigationDelegate {
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var publishButton: UIBarButtonItem!
    
    internal var delegate: PublisherDelegate?
    internal var blogUrl = String()
    internal var mediaType = String()
    internal var name = String()
    internal var tags = String()
    internal var descriptor = String()
    internal var date = String()
    internal var webUrlString = String()
    internal var latitude = Double()
    internal var longitude = Double()
    
    private var webView: WKWebView
    private var myContext = 0
    
    // Use this for name and tags
    func javascriptUnicode(string: String) -> String {
        var newString = ""
        for char in string {
            var str = String(char)
            var data = str.dataUsingEncoding(NSUTF16StringEncoding)
            if let charData = data {
                let hexChar = charData.toUTF8String()
                newString += "\\u" + hexChar
            }
        }
        
        return newString
    }
    
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
        blogUrl = cleanHttpAddress(blogUrl)
        blogUrl = blogUrl + "wp-admin/post-new.php"
        let url = NSURL(string: blogUrl)!
        let request = NSURLRequest(URL:url)
        webView.loadRequest(request)
        
        name = javascriptUnicode(name)
        tags = javascriptUnicode(tags)
        descriptor = javascriptUnicode(descriptor)
    }
    
    override func viewDidAppear(animated: Bool) {
        return super.viewDidAppear(true)
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
            if webView.estimatedProgress == 1 {
                progressView.hidden = true
                self.backButton.enabled = true
                self.publishButton.enabled = true
            }
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
        self.delegate?.updatePublishStatus(false)
        self.navigationController?.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func publishButtonPressed(sender: UIBarButtonItem) {
        
        backButton.enabled = false
        publishButton.enabled = false
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        
        var postFormat: String = ""
        var body: String = ""
        
        switch mediaType {
        case "image":
            postFormat = "post-format-image"
            body = "<img src=\"\(webUrlString)\" width=\"640\" height=\"480\">"
        case "video":
            postFormat = "post-format-video"
            body = "[video mp4=\"\(webUrlString)\"]"
        case "recording":
            postFormat = "post-format-audio"
            body = "[audio m4a=\"\(webUrlString)\"]"
        default:
            postFormat = "post-format-standard"
            body = ""
        }
        
        body = body + "<p><br>\(descriptor)</p>"
        body = body + "<p>&nbsp;</p>[wp_gmaps lat=\"\(latitude)\" lng=\"\(longitude)\" zoom=\"12\" marker=\"1\"]"
        body = body + "<code>\(date)</code>"
        
        var clearTitlePlaceholder = "document.getElementById('title-prompt-text').className='screen-reader-text';"
        var setTitle = "document.getElementById('title').value='\(name)';"
        var setTags = "document.getElementById('new-tag-post_tag').value='\(tags)';"
        var clickAddTags = "document.getElementsByClassName('button tagadd')[0].click();"
        var setBody = "document.getElementById('content').innerHTML = '\(body)'"
        var setContentType = "document.getElementById('\(postFormat)').checked=true;"
        var clickPublishButton = "document.getElementsByClassName('button button-primary button-large')[0].click();"
        
        webView.evaluateJavaScript(clearTitlePlaceholder, completionHandler: nil)
        webView.evaluateJavaScript(setTitle, completionHandler: nil)
        webView.evaluateJavaScript(setTags, completionHandler: nil)
        webView.evaluateJavaScript(clickAddTags, completionHandler: nil)
        webView.evaluateJavaScript(setBody, completionHandler: nil)
        webView.evaluateJavaScript(setContentType, completionHandler: nil)
        webView.evaluateJavaScript(clickPublishButton, completionHandler: nil)
        
        UIApplication.sharedApplication().endIgnoringInteractionEvents()
    }
    
    func cleanHttpAddress(mask: String) -> String {
        var str = mask
        if str[str.endIndex.predecessor()] != "/" && count(str) > 0 {
            str = str + "/"
        }
        str = str.stringByReplacingOccurrencesOfString("ftp://", withString: "http://", options: NSStringCompareOptions.LiteralSearch, range: nil)
        
        if !str.hasPrefix("http://") {
            str = "http://" + str
        }
        return str
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