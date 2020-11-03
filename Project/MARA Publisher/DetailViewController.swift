//
//  DetailViewController.swift
//  MARA Publisher
//
//  Created by Shree Raj Shrestha on 8/10/15.
//  Copyright (c) 2015 Shree Raj Shrestha. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AVKit
import CoreData
import MapKit

class DetailViewController: UIViewController, AVAudioPlayerDelegate, MKMapViewDelegate, FDWaveformViewDelegate, FTPUploaderDelegate, PublisherDelegate, ALTextInputBarDelegate {
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tagListView: TagListView!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var videoContainer: UIView!
    @IBOutlet weak var waveform: FDWaveformView!
    @IBOutlet weak var waveformButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var uploadButton: UIBarButtonItem!
    @IBOutlet weak var publishButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    @IBOutlet weak var containerViewWidth: NSLayoutConstraint!
    
    internal var mediaType = String()
    internal var mediaObject: NSManagedObject?
    internal var isPublishing: Bool = false
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: NSTimer?
    private var webStatusTimer: NSTimer?
    private var fileURL: NSURL?
    private var nextButton: UIButton!
    
    private var name = String()
    private var tags = String()
    private var descriptor = String()
    private var date = String()
    private var webUrlString = String()
    private var latitude = Double()
    private var longitude = Double()
    
    private var fileName = String()
    private var filePath = String()
    private var fileManager = NSFileManager()
    private var inputType = String()
    private var webURL = NSURL()
    
    private var webUrlExists: Bool = false
    private var isEditing: Bool = false
    private var isUploading: Bool = false
    private var isDeleting: Bool = false
    private var uploadRetries: Int = 4
    
    private var uploader = FTPUploader()
    private let textInputBar = ALTextInputBar()
    private let keyboardObserver = ALKeyboardObservingView()
    private let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    override var inputAccessoryView: UIView? {
        get {
            return keyboardObserver
        }
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    func setDisplayConstraints() {
        var screenSize: CGSize = UIScreen.mainScreen().bounds.size as CGSize
        var height: CGFloat = screenSize.height
        var width: CGFloat = screenSize.width
        
        if height < width {
            var temp = height
            height = width
            width = temp
        }
        
        // iPhone 5s/5, 4s
        if (height == 568.0 || height == 480.0) && width == 320.0 {
            containerViewWidth.constant = width
            contentViewHeight.constant = 750.0
        }
            // iPhone 6
        else if height == 667.0 && width == 375.0 {
            containerViewWidth.constant = width
            contentViewHeight.constant = 834.0
        }
            // iPhone 6 Plus
        else if height == 736.0 && width == 414.0 {
            containerViewWidth.constant = width
            contentViewHeight.constant = 890.0
        }
            // iPad
        else if height == 1024.0 && width == 768.0 {
            contentViewHeight.constant = height - 65.0
            containerViewWidth.constant = 458.0
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setDisplayConstraints()
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
        let documentsDirectory = paths.objectAtIndex(0) as! String
        
        if mediaObject?.valueForKey("url") != nil {
            webUrlString = mediaObject?.valueForKey("url") as! String
        }
        webURL = NSURL(string: webUrlString)!
        
        switch mediaType {
            
        case "image":
            imagePreview.hidden = false
            imagePreview.userInteractionEnabled = true
            let imageObject = mediaObject as! ImageDB
            name = imageObject.name
            tags = imageObject.tags
            descriptor = imageObject.descriptor
            latitude = Double(imageObject.latitude)
            longitude = Double(imageObject.longitude)
            date = imageObject.date
            fileName = imageObject.fileName
            
            let pathComponents = NSArray(objects: documentsDirectory, "/Images/", imageObject.fileName)
            let url = NSURL.fileURLWithPathComponents(pathComponents as [AnyObject])!
            imagePreview.image = UIImage(contentsOfFile: url.path!)
            fileURL = url
            filePath = url.path!
            
        case "video":
            videoContainer.hidden = false
            videoContainer.userInteractionEnabled = true
            let videoObject = mediaObject as! VideoDB
            name = videoObject.name
            tags = videoObject.tags
            descriptor = videoObject.descriptor
            latitude = Double(videoObject.latitude)
            longitude = Double(videoObject.longitude)
            date = videoObject.date
            fileName = videoObject.fileName
            
            let pathComponents = NSArray(objects: documentsDirectory, "/Videos/", videoObject.fileName)
            let url = NSURL.fileURLWithPathComponents(pathComponents as [AnyObject])!
            let embededVC = self.childViewControllers[0] as! AVPlayerViewController
            let session = AVAudioSession.sharedInstance()
            session.setMode(AVAudioSessionModeMoviePlayback, error: nil)
            embededVC.player = AVPlayer(URL: url)
            fileURL = url
            filePath = url.path!
            
        case "recording":
            waveform.hidden = false
            waveform.userInteractionEnabled = true
            waveformButton.hidden = false
            let recordingObject = mediaObject as! RecordingDB
            name = recordingObject.name
            tags = recordingObject.tags
            descriptor = recordingObject.descriptor
            latitude = Double(recordingObject.latitude)
            longitude = Double(recordingObject.longitude)
            date = recordingObject.date
            fileName = recordingObject.fileName
            
            let pathComponents = NSArray(objects: documentsDirectory, "/Recordings/", recordingObject.fileName)
            let url = NSURL.fileURLWithPathComponents(pathComponents as [AnyObject])!
            fileURL = url
            filePath = url.path!
            initWaveform()
            
        default:
            videoContainer.hidden = true
            imagePreview.hidden = true
            waveform.hidden = true
            waveformButton.hidden = true
        }
        
        titleLabel.text = name
        dateLabel.text = date
        descriptionTextView.selectable = true
        descriptionTextView.text = descriptor
        descriptionTextView.selectable = false
        tagListView.removeAllTags()
        tagListView.textFont = UIFont.systemFontOfSize(11)
        let tagsArray = tags.componentsSeparatedByString(",")
        for tag in tagsArray {
            tagListView.addTag(tag)
        }
        
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let span = MKCoordinateSpanMake(0.025, 0.025)
        let region = MKCoordinateRegion(center: location.coordinate, span: span)
        let pin = MKPointAnnotation()
        pin.coordinate = location.coordinate
        pin.title = name
        pin.subtitle = tags
        
        mapView.mapType = MKMapType.Standard
        mapView.zoomEnabled = false
        mapView.scrollEnabled = false
        mapView.pitchEnabled = false
        mapView.rotateEnabled = true
        mapView.centerCoordinate = location.coordinate
        mapView.addAnnotation(pin)
        mapView.delegate = self
        mapView.setRegion(region, animated: true)
        
        configureInputBar()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardFrameChanged:", name: ALKeyboardFrameDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        isEditing = false
        
        updateWebButtonStatus()
        
        if internetAvailable() {
            progressView.setProgress(1.0, animated: false)
        }
        
        uploadRetries = 4
        
        self.webStatusTimer = NSTimer.scheduledTimerWithTimeInterval(0.25, target: self, selector: "updateWebButtonStatus", userInfo: nil, repeats: true)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        textInputBar.frame.size.width = view.bounds.size.width
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var screenSize: CGSize = UIScreen.mainScreen().bounds.size as CGSize
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
    
    func fileExists(url : NSURL!) -> Bool {
        if url.path != nil {
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "HEAD"
            
            var response : NSURLResponse?
            var error: NSError?
            NSURLConnection.sendSynchronousRequest(request, returningResponse: &response , error: &error)
            if let err = error {
                println("NSURLConnection sendSynchronousRequest error: \(err.localizedDescription)")
            }
            
            if let httpResponse = response as? NSHTTPURLResponse {
                var fileSize : UInt64
                var attr:NSDictionary? = NSFileManager.defaultManager().attributesOfItemAtPath(filePath, error: nil)
                if let _attr = attr {
                    fileSize = _attr.fileSize();
                }
                else {
                    fileSize = 0
                }
                return Int64(fileSize) == httpResponse.expectedContentLength
            }
        }
        return false
    }
    
    
    func updateWebButtonStatus() {
        if !isUploading && !isEditing && !isDeleting && !isPublishing {
            var isInternetAvailable = internetAvailable()
            var isFileExists = fileExists(webURL)
            
            if isInternetAvailable {
                progressView.setProgress(1.0, animated: false)
            }
            else {
                progressView.setProgress(0.0, animated: false)
            }
            
            uploadButton.enabled = !isFileExists && isInternetAvailable
            publishButton.enabled = isFileExists && isInternetAvailable
        }
    }
    
    func typeButtonPressed(sender: UIButton!) {
        switch inputType {
            
        case "tags":
            tags = textInputBar.text
            let tagsArray = tags.componentsSeparatedByString(",")
            tagListView.removeAllTags()
            for tag in tagsArray {
                tagListView.addTag(tag)
            }
            textInputBar.textView.text = descriptor
            inputType = "description"
            UIView.animateWithDuration(1.5, delay:0.0, options: .CurveEaseInOut | .Autoreverse | .AllowUserInteraction | .Repeat, animations: {
                self.nextButton.alpha = 0.1
                }, completion: nil)
            
        case "description":
            descriptor = textInputBar.text
            descriptionTextView.selectable = true
            descriptionTextView.text = descriptor
            descriptionTextView.selectable = false
            inputType = "complete"
            
        default:
            name = textInputBar.text
            titleLabel.text = name
            textInputBar.textView.text = tags
            inputType = "tags"
        }
        
        if inputType == "complete" {
            nextButton.layer.removeAllAnimations()
            textInputBar.textView.userInteractionEnabled = false
            textInputBar.textView.resignFirstResponder()
            textInputBar.hidden = true
            editButton.enabled = true
        }
    }
    
    func configureInputBar() {
        nextButton = UIButton(frame: CGRectMake(0, 0, 44, 44))
        nextButton.addTarget(self, action: "typeButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        nextButton.setImage(UIImage(named: "textInput"), forState: UIControlState.Normal)
        
        keyboardObserver.userInteractionEnabled = false
        textInputBar.leftView = nil
        textInputBar.rightView = nextButton
        textInputBar.alwaysShowRightButton = true
        textInputBar.frame = CGRectMake(0, view.frame.size.height - textInputBar.defaultHeight, view.frame.size.width, textInputBar.defaultHeight)
        textInputBar.horizontalPadding = 10
        textInputBar.backgroundColor = UIColor.groupTableViewBackgroundColor()
        textInputBar.keyboardObserver = keyboardObserver
        textInputBar.textView.keyboardType = UIKeyboardType.ASCIICapable
        textInputBar.textView.autocapitalizationType = UITextAutocapitalizationType.None
        textInputBar.textView.returnKeyType = UIReturnKeyType.Default
        textInputBar.delegate = self
    }
    
    func keyboardFrameChanged(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let frame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            textInputBar.frame.origin.y = frame.origin.y
        }
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let frame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            textInputBar.frame.origin.y = frame.origin.y
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let frame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            textInputBar.frame.origin.y = frame.origin.y
        }
    }
    
    func deactivateAudioSession() {
        var audioSession = AVAudioSession.sharedInstance()
        audioSession.setActive(false, error: nil)
    }
    
    func generateWaveform() {
        waveform.delegate = self
        waveform.alpha = 0.0 as CGFloat!
        waveform.audioURL = fileURL
        waveform.progressSamples = 0.0 as UInt!
        waveform.doesAllowScrubbing = false
        waveform.doesAllowStretchAndScroll = false
    }
    
    func updateWaveform() {
        UIView.animateWithDuration(0.001, animations: {
            let currentPlayTime = self.audioPlayer?.currentTime
            let progressSample = UInt((currentPlayTime! + 0.01) * 44100.00)
            self.waveform.progressSamples = progressSample
        })
    }
    
    func resetWaveform() {
        self.timer?.invalidate()
        waveform.progressSamples = 0.0 as UInt!
    }
    
    func initWaveform() {
        self.resetWaveform()
        self.generateWaveform()
        self.waveformButton.enabled = true
        var error: NSError?
        var audioSession = AVAudioSession.sharedInstance()
        audioSession.setCategory(AVAudioSessionCategoryPlayback, error: nil)
        audioSession.setActive(true, error: nil)
        audioPlayer = AVAudioPlayer(contentsOfURL: fileURL, error: &error)
        audioPlayer?.delegate = self
        if let err = error {
            println("audioPlayer error: \(err.localizedDescription)")
        }
    }
    
    @IBAction func cancelButtonPressed(sender: UIBarButtonItem) {
        self.webStatusTimer?.invalidate()
        self.navigationController?.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func waveformButtonPressed(sender: UIButton) {
        if audioPlayer?.playing == false {
            waveformButton.setImage(UIImage(named: "pause"), forState: UIControlState.Normal)
            self.timer = NSTimer.scheduledTimerWithTimeInterval(0.001, target: self, selector: "updateWaveform", userInfo: nil, repeats: true)
            audioPlayer?.play()
        }
        else {
            waveformButton.setImage(UIImage(named: "play"), forState: UIControlState.Normal)
            audioPlayer?.pause()
        }
    }
    
    @IBAction func editButtonPressed(sender: UIBarButtonItem) {
        if !isEditing {
            deleteButton.enabled = false
            cancelButton.enabled = false
            editButton.enabled = false
            uploadButton.enabled = false
            publishButton.enabled = false
            editButton.image = UIImage(named: "useAudio")
            view.addSubview(textInputBar)
            textInputBar.hidden = false
            textInputBar.textView.text = name
            textInputBar.textView.userInteractionEnabled = true
            textInputBar.textView.becomeFirstResponder()
            isEditing = true
        }
        else {
            mediaObject?.setValue(name, forKey: "name")
            mediaObject?.setValue(tags, forKey: "tags")
            mediaObject?.setValue(descriptor, forKey: "descriptor")
            mediaObject?.setValue(longitude, forKey: "longitude")
            mediaObject?.setValue(latitude, forKey: "latitude")
            mediaObject?.setValue(date, forKey: "date")
            mediaObject?.setValue(fileName, forKey: "fileName")
            
            var error: NSError?
            self.managedObjectContext?.save(&error)
            if let err = error {
                println("managedObjectContext edited save error: \(err.localizedDescription)")
            }
            
            deleteButton.enabled = true
            cancelButton.enabled = true
            editButton.image = UIImage(named: "edit")
            textInputBar.textView.userInteractionEnabled = false
            textInputBar.textView.resignFirstResponder()
            textInputBar.hidden = true
            isEditing = false
            updateWebButtonStatus()
        }
    }
    
    @IBAction func deleteButtonPressed(sender: UIBarButtonItem) {
        
        isDeleting = true
        
        let alert = UIAlertController(title: "Delete?",
            message: "The media file and its metadata will be deleted from your library. \n\nHowever, this does not affect the file uploaded to the server and any posts published for this media.",
            preferredStyle: UIAlertControllerStyle.Alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action) in
            self.isDeleting = false
        }
        let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.Destructive) { (action) in
            self.managedObjectContext?.deleteObject(self.mediaObject!)
            var error: NSError?
            self.managedObjectContext?.save(&error)
            if let err = error {
                println("managedObjectContext delete error: \(err.localizedDescription)")
            } else {
                var error2: NSError?
                self.fileManager.removeItemAtURL(self.fileURL!, error: &error2)
                if let err2 = error2 {
                    println("fileManager delete error: \(err2.localizedDescription)")
                } else {
                    self.webStatusTimer?.invalidate()
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            }
            self.isDeleting = false
        }
        alert.addAction(cancelAction)
        alert.addAction(yesAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func uploadButtonPressed(sender: UIBarButtonItem) {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if let ftpUrl = defaults.objectForKey("ftpUrl") as? String {
            uploader.FTPURL = ftpUrl.isEmpty ? nil : ftpUrl
        }
        
        if let ftpUsername = defaults.objectForKey("ftpUsername") as? String {
            uploader.FTPUsername = ftpUsername.isEmpty ? nil : ftpUsername
        }
        
        var error: NSError?
        if let ftpPassword = SSKeychain.passwordForService("mara.ftp", account: defaults.objectForKey("ftpUsername") as? String, error: &error) {
            uploader.FTPPassword = ftpPassword.isEmpty ? nil : ftpPassword
        }
        
        var ftpDetailsSet = true
        if uploader.FTPURL == nil || uploader.FTPUsername == nil || uploader.FTPPassword == nil {
            ftpDetailsSet = false
            let alert = UIAlertController(title: "FTP Details Not Set!", message: "To upload the file to the server, please enter or import the ftp details in the settings page.", preferredStyle: .Alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
            let settingsAction = UIAlertAction(title: "Open Settings", style: .Default) { (action) in
                let settingsNC = self.storyboard?.instantiateViewControllerWithIdentifier("settingsNC") as! UIViewController
                settingsNC.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
                self.presentViewController(settingsNC, animated: true, completion: nil)
            }
            
            alert.addAction(cancelAction)
            alert.addAction(settingsAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
        if ftpDetailsSet {
            isUploading = true
            progressView.setProgress(0.0, animated: false)
            
            cancelButton.enabled = false
            editButton.enabled = false
            deleteButton.enabled = false
            uploadButton.enabled = false
            
            uploader.sourceFilePath = filePath
            uploader.delegate = self
            uploader.startUpload()
        }
    }
    
    @IBAction func publishButtonPressed(sender: UIBarButtonItem) {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let blogUrl = defaults.objectForKey("blogUrl") as? String {
            if blogUrl.isEmpty {
                let alert = UIAlertController(title: "Blog URL Not Set!", message: "To publish post, please enter the blog user in the settings page.", preferredStyle: .Alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
                let settingsAction = UIAlertAction(title: "Open Settings", style: .Default) { (action) in
                    let settingsNC = self.storyboard?.instantiateViewControllerWithIdentifier("settingsNC") as! UIViewController
                    settingsNC.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
                    self.presentViewController(settingsNC, animated: true, completion: nil)
                }
                
                alert.addAction(cancelAction)
                alert.addAction(settingsAction)
                self.presentViewController(alert, animated: true, completion: nil)
            }
            else {
                isPublishing = true
                let publishNC = self.storyboard?.instantiateViewControllerWithIdentifier("publishNC") as! UINavigationController
                publishNC.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
                
                let publishVC = publishNC.viewControllers[0] as! PublishViewController
                publishVC.delegate = self
                publishVC.blogUrl = defaults.objectForKey("blogUrl") as! String
                publishVC.mediaType = mediaType
                publishVC.name = name
                publishVC.tags = tags
                publishVC.descriptor = descriptor
                publishVC.date = date
                publishVC.webUrlString = webUrlString
                publishVC.latitude = latitude
                publishVC.longitude = longitude
                
                self.presentViewController(publishNC, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - ALTextView Delegate
    func textViewShouldReturn(textView: ALTextView) -> Bool {
        if inputType == "description" {
            return true
        }
        if count(textView.text) == 0 {
            let alert = UIAlertController(title: "Text Field Empty!", message: "Please type in some text to proceed.", preferredStyle: UIAlertControllerStyle.Alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
            alert.addAction(okAction)
            self.presentViewController(alert, animated: true, completion: nil)
            return false
        }
        typeButtonPressed(UIButton())
        return false
    }
    
    // MARK: - FDWaveformViewDelegate
    
    func waveformViewWillRender(waveformView: FDWaveformView!) {
    }
    
    func waveformViewDidRender(waveformView: FDWaveformView!) {
        UIView.animateWithDuration(0.001, animations: {
            self.waveform.alpha = 0.95
        })
    }
    
    // MARK: - Audio Player
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        deactivateAudioSession()
        waveformButton.setImage(UIImage(named: "play"), forState: UIControlState.Normal)
        self.resetWaveform()
    }
    
    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer!, error: NSError!) {
        println("Audio Play Decode Error: \(error.localizedDescription)")
    }
    
    // MARK: - FTPUploader Delegate
    
    func updateProgress(progress: Float) {
        progressView.setProgress(progress, animated: true)
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
    
    func uploadedSuccessfullyToURL(URL: NSURL!) {
        let defaults = NSUserDefaults.standardUserDefaults()
        var useHttpMask = defaults.boolForKey("useHttpMask")
        if useHttpMask {
            webUrlString = defaults.objectForKey("httpMask") as! String
            webUrlString = cleanHttpAddress(webUrlString)
            webUrlString = webUrlString + URL.lastPathComponent!
        }
        else {
            webUrlString = URL.absoluteString!
            webUrlString = cleanHttpAddress(webUrlString)
        }
        
        webURL = NSURL(string: webUrlString)!
        mediaObject?.setValue(webUrlString, forKey:"url")
        var error: NSError?
        self.managedObjectContext?.save(&error)
        if let err = error {
            println("managedObjectContext edited save error: \(err.localizedDescription)")
        }
        cancelButton.enabled = true
        editButton.enabled = true
        deleteButton.enabled = true
        isUploading = false
        updateWebButtonStatus()
    }
    
    func uploadDidFailWithError(error: String!) {
        if self.uploadRetries == 0 {
            let alert = UIAlertController(title: "Network Stream Open Error!", message: "Uploading the file requires a working ftp connection, please verify and fill completely the ftp details in the settings page.", preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
            let settingsAction = UIAlertAction(title: "Open Settings", style: .Default) { (action) in
                let settingsNC = self.storyboard?.instantiateViewControllerWithIdentifier("settingsNC") as! UIViewController
                settingsNC.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
                self.presentViewController(settingsNC, animated: true, completion: nil)
            }
            
            alert.addAction(okAction)
            alert.addAction(settingsAction)
            self.presentViewController(alert, animated: true, completion: nil)
            
            progressView.setProgress(0.0, animated: false)
            cancelButton.enabled = true
            editButton.enabled = true
            deleteButton.enabled = true
            isUploading = false
            updateWebButtonStatus()
            uploadRetries = 4
        }
        else {
            uploader.startUpload()
            self.uploadRetries -= 1
            println("\(error), Retrying... retries left = \(uploadRetries)")
        }
    }
    
    // MARK: PublisherDelegate
    func updatePublishStatus(isPublishing: Bool) {
        self.isPublishing = isPublishing
    }
}