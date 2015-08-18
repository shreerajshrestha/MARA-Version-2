//
//  AddMediaViewController.swift
//  MARA for iPhone
//
//  Created by Shree Raj Shrestha on 7/27/15.
//  Copyright (c) 2015 Shree Raj Shrestha. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices
import CoreLocation
import AVFoundation
import AVKit
import CoreData
import MapKit

class AddMediaViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate,  CLLocationManagerDelegate, AVAudioPlayerDelegate, MKMapViewDelegate, RecorderDelegate, FDWaveformViewDelegate , ALTextInputBarDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tagListView: TagListView!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var videoContainer: UIView!
    @IBOutlet weak var waveform: FDWaveformView!
    @IBOutlet weak var waveformButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var captureButton: UIButton!
    
    internal var mediaType = String()
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: NSTimer?
    private var tempURL: NSURL?
    private var fileURL: NSURL?
    private var nextButton: UIButton!
    
    private var name = String()
    private var tags = String()
    private var descriptor = String()
    private var latitude = Double()
    private var longitude = Double()
    private var tempPath = String()
    private var documentsFolder = String()
    private var camera = UIImagePickerController()
    private var fileManager = NSFileManager()
    private var locationManager = CLLocationManager()
    private var inputType = String()
    
    private let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    private let textInputBar = ALTextInputBar()
    private let keyboardObserver = ALKeyboardObservingView()
    
    override var inputAccessoryView: UIView? {
        get {
            return keyboardObserver
        }
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        camera.delegate = self
        locationManager.delegate = self
        
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let span = MKCoordinateSpanMake(0.10, 0.10)
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
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
        let documentsDirectory = paths.objectAtIndex(0) as! NSString
        
        switch mediaType {
        case "image":
            imagePreview.hidden = false
            imagePreview.userInteractionEnabled = true
            tempPath = NSTemporaryDirectory().stringByAppendingString("temp.jpg")
            documentsFolder = documentsDirectory.stringByAppendingString("/Images/")
            captureButton.setImage(UIImage(named: "imageNav"), forState: UIControlState.Normal)
        case "video":
            videoContainer.hidden = false
            videoContainer.userInteractionEnabled = true
            tempPath = NSTemporaryDirectory().stringByAppendingString("temp.mp4")
            documentsFolder = documentsDirectory.stringByAppendingString("/Videos/")
            captureButton.setImage(UIImage(named: "videoNav"), forState: UIControlState.Normal)
        case "recording":
            waveform.hidden = false
            waveform.userInteractionEnabled = true
            waveformButton.hidden = false
            tempPath = NSTemporaryDirectory().stringByAppendingString("temp.m4a")
            documentsFolder = documentsDirectory.stringByAppendingString("/Recordings/")
            captureButton.setImage(UIImage(named: "recordingNav"), forState: UIControlState.Normal)
        default:
            videoContainer.hidden = true
            imagePreview.hidden = true
            waveform.hidden = true
            waveformButton.hidden = true
        }
        
        var error: NSError?
        if !fileManager.fileExistsAtPath(documentsFolder as String) {
            fileManager.createDirectoryAtPath(documentsFolder as String, withIntermediateDirectories: false, attributes: nil, error: &error)
        }
        if let err = error {
            println("fileManager error: \(err.localizedDescription)")
        }
        tempURL = NSURL.fileURLWithPath(tempPath)
        
        configureInputBar()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardFrameChanged:", name: ALKeyboardFrameDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
        tagListView.textFont = UIFont.systemFontOfSize(11)
        tagListView.addTag("tag1")
        tagListView.addTag("tag2")
        tagListView.addTag("tag3")
        saveButton.enabled = false
        
        switch CLLocationManager.authorizationStatus() {
        case .NotDetermined:
            locationManager.requestWhenInUseAuthorization()
            locationManager.distanceFilter = kCLDistanceFilterNone
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        case .Restricted, .Denied:
            let alert = UIAlertController(title: "Location Access Disabled!",
                message: "Location data is required to save metadata for the media. Please open settings and set the location access to \n'While Using the App'.",
                preferredStyle: UIAlertControllerStyle.Alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
            let openSettingsAction = UIAlertAction(title: "Open Settings", style: .Default) { (action) in
                if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                    UIApplication.sharedApplication().openURL(url)
                }
            }
            alert.addAction(cancelAction)
            alert.addAction(openSettingsAction)
            self.presentViewController(alert, animated: true, completion: nil)
        default:
            locationManager.distanceFilter = kCLDistanceFilterNone
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
        
        UIView.animateWithDuration(1.5, delay:0.0, options: .CurveEaseInOut | .Autoreverse | .AllowUserInteraction | .Repeat, animations: {
            self.captureButton.alpha = 0.1
            }, completion: nil)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        textInputBar.frame.size.width = view.bounds.size.width
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var screenSize: CGSize = UIScreen.mainScreen().bounds.size as CGSize
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
            textInputBar.textView.placeholder = "Enter the description text..."
            textInputBar.text = ""
            inputType = "description"
            
            let pin = MKPointAnnotation()
            let location = CLLocation(latitude: latitude, longitude: longitude)
            pin.coordinate = location.coordinate
            pin.title = name
            pin.subtitle = tags
            mapView.addAnnotation(pin)
            
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
            textInputBar.textView.placeholder = "Enter tags separated by commas..."
            textInputBar.text = ""
            inputType = "tags"
        }
        
        if inputType == "complete" {
            nextButton.layer.removeAllAnimations()
            textInputBar.textView.userInteractionEnabled = false
            textInputBar.textView.resignFirstResponder()
            textInputBar.hidden = true
        }
        textInputBar.text = ""
    }
    
    func configureInputBar() {
        nextButton = UIButton(frame: CGRectMake(0, 0, 44, 44))
        nextButton.addTarget(self, action: "typeButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        nextButton.setImage(UIImage(named: "textInput"), forState: UIControlState.Normal)
        
        keyboardObserver.userInteractionEnabled = false
        textInputBar.leftView = nil
        textInputBar.rightView = nextButton
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
    
    func showCamera() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            camera.sourceType = UIImagePickerControllerSourceType.Camera
            camera.allowsEditing = false
            camera.showsCameraControls = true
            if mediaType == "image" {
                camera.mediaTypes = [kUTTypeImage]
            } else if mediaType == "video" {
                camera.mediaTypes = [kUTTypeMovie]
            }
            self.presentViewController(camera, animated: true, completion: nil)
        }
    }
    
    func deactivateAudioSession() {
        var audioSession = AVAudioSession.sharedInstance()
        audioSession.setActive(false, error: nil)
    }
    
    func generateWaveform() {
        waveform.delegate = self
        waveform.alpha = 0.0 as CGFloat!
        waveform.audioURL = tempURL
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
    
    func validateInputFields() -> Bool {
        if name == "" {
            return false
        }
        if tags == "" {
            return false
        }
        if descriptor == "" {
            return false
        }
        if latitude == 0 || longitude == 0 {
            return false
        }
        return fileManager.fileExistsAtPath(tempPath)
    }
    
    @IBAction func cancelButtonPressed(sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Are You Sure?", message: "Any captured media and input data will be cleared!", preferredStyle: UIAlertControllerStyle.Alert)
        let stayAction = UIAlertAction(title: "Stay", style: UIAlertActionStyle.Cancel, handler: nil)
        let backAction = UIAlertAction(title: "Leave", style: UIAlertActionStyle.Destructive) { (action) in
            self.navigationController?.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
            self.textInputBar.textView.resignFirstResponder()
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        alert.addAction(stayAction)
        alert.addAction(backAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }

    @IBAction func captureButtonPressed(sender: UIButton) {
        if mediaType == "recording" {
            let recorderNC = self.storyboard?.instantiateViewControllerWithIdentifier("recorderNC") as! UINavigationController
            recorderNC.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
            let recorderVC = recorderNC.viewControllers[0] as! RecorderViewController
            fileManager.removeItemAtPath(tempPath, error: nil)
            recorderVC.filePath = tempPath
            recorderVC.delegate = self
            self.presentViewController(recorderNC, animated: true, completion: nil)
        } else {
            showCamera()
        }
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
    
    @IBAction func saveButtonTapped(sender: UIBarButtonItem) {
        if validateInputFields() {
            let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
            let documentsDirectory = paths.objectAtIndex(0) as! NSString
            
            let fileExists = false
            var fileName = NSString()
            
            do {
                var pathComponents = NSArray()
                
                var str = name as String
                var cleanName = ""
                var charSet = NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890")
                for char in str {
                    if String(char).rangeOfCharacterFromSet(charSet, options: nil, range: nil) != nil {
                        cleanName = cleanName + String(char)
                    }
                }
                cleanName = cleanName.stringByReplacingOccurrencesOfString(" ", withString: "", options: .LiteralSearch, range: nil)
                if count(cleanName) == 0 {
                    cleanName = "Random"
                }
                
                let id = arc4random() % 999999999
                switch mediaType {
                case "image":
                    fileName = String(format: "%@%d.jpg", cleanName, id)
                    pathComponents = NSArray(objects: documentsDirectory, "/Images/", fileName)
                case "video":
                    fileName = String(format: "%@%d.mp4", cleanName, id)
                    pathComponents = NSArray(objects: documentsDirectory, "/Videos/", fileName)
                case "recording":
                    fileName = String(format: "%@%d.m4a", cleanName, id)
                    pathComponents = NSArray(objects: documentsDirectory, "/Recordings/", fileName)
                default:
                    pathComponents = NSArray()
                }
                fileURL = NSURL.fileURLWithPathComponents(pathComponents as [AnyObject])!
            } while fileExists == true
            
            var error: NSError?
            fileManager.copyItemAtURL(tempURL!, toURL: fileURL!, error: &error)
            if let err = error {
                println("fileManager error: \(err.localizedDescription)")
            }
            
            let formatter = NSDateFormatter()
            formatter.timeStyle = NSDateFormatterStyle.LongStyle
            formatter.dateStyle = NSDateFormatterStyle.LongStyle
            formatter.locale = NSLocale(localeIdentifier: "en_US")
            let now = NSDate()
            let date = formatter.stringFromDate(now)
            
            switch mediaType {
            case "image":
                let imageObject = NSEntityDescription.insertNewObjectForEntityForName("ImageDB", inManagedObjectContext: self.managedObjectContext!) as! ImageDB
                imageObject.name = name
                imageObject.tags = tags
                imageObject.descriptor = descriptor
                imageObject.longitude = longitude
                imageObject.latitude = latitude
                imageObject.date = date
                imageObject.fileName = fileName as String
                
            case "video":
                let videoObject = NSEntityDescription.insertNewObjectForEntityForName("VideoDB", inManagedObjectContext: self.managedObjectContext!) as! VideoDB
                videoObject.name = name
                videoObject.tags = tags
                videoObject.descriptor = descriptor
                videoObject.longitude = longitude
                videoObject.latitude = latitude
                videoObject.date = date
                videoObject.fileName = fileName as String
                
            default:
                let recordingObject = NSEntityDescription.insertNewObjectForEntityForName("RecordingDB", inManagedObjectContext: self.managedObjectContext!) as! RecordingDB
                recordingObject.name = name
                recordingObject.tags = tags
                recordingObject.descriptor = descriptor
                recordingObject.longitude = longitude
                recordingObject.latitude = latitude
                recordingObject.date = date
                recordingObject.fileName = fileName as String
            }
            
            self.managedObjectContext?.save(&error)
            if let err = error {
                println("managedObjectContext error: \(err.localizedDescription)")
            } else {
                let alert = UIAlertController(title: "Successfully Saved!", message: "The media has been added to your library.", preferredStyle: UIAlertControllerStyle.Alert)
                let okAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                    self.navigationController?.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
                alert.addAction(okAction)
                self.presentViewController(alert, animated: true, completion: nil)  
            }
        }
        else {
            let alert = UIAlertController(title: "Not Yet!", message: "Please input all required details in the text field below before saving!", preferredStyle: UIAlertControllerStyle.Alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
            alert.addAction(okAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
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
    
    /*
    func textViewDidChange(textView: ALTextView) {
        var str = textView.text as String
        if str.startIndex != str.endIndex {
            println(str[str.endIndex.predecessor()])
        }
    }
    */
    
    
    // MARK: - Image Picker Controller
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        switch mediaType {
        case "image":
            let capturedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
            fileManager.removeItemAtPath(tempPath, error: nil)
            UIImageJPEGRepresentation(capturedImage, 1.0).writeToFile(tempPath, atomically: true)
            if let tempImage = UIImage(contentsOfFile: tempPath) {
                imagePreview.image = tempImage
                captureButton.layer.removeAllAnimations()
                captureButton.enabled = false
                saveButton.enabled = true
                view.addSubview(textInputBar)
                textInputBar.textView.placeholder = "Enter title for the media"
                textInputBar.textView.userInteractionEnabled = true
                textInputBar.textView.becomeFirstResponder()
                locationManager.startUpdatingLocation()
            }
        case "video":
            var capturedVideoURL: NSURL = info[UIImagePickerControllerMediaURL] as! NSURL
            fileManager.removeItemAtURL(tempURL!, error: nil)
            fileManager.copyItemAtURL(capturedVideoURL, toURL: tempURL!, error: nil)
            let embededVC = self.childViewControllers[0] as! AVPlayerViewController
            let session = AVAudioSession.sharedInstance()
            session.setMode(AVAudioSessionModeMoviePlayback, error: nil)
            embededVC.player = AVPlayer(URL: tempURL)
            captureButton.layer.removeAllAnimations()
            captureButton.enabled = false
            saveButton.enabled = true
            view.addSubview(textInputBar)
            textInputBar.textView.placeholder = "Enter title for the media"
            textInputBar.textView.userInteractionEnabled = true
            textInputBar.textView.becomeFirstResponder()
            locationManager.startUpdatingLocation()
        default:
            dismissViewControllerAnimated(true, completion: nil)
        }
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - FDWaveformViewDelegate
    
    func waveformViewWillRender(waveformView: FDWaveformView!) {
    }
    
    func waveformViewDidRender(waveformView: FDWaveformView!) {
        UIView.animateWithDuration(0.001, animations: {
            self.waveform.alpha = 0.95
        })
    }
    
    // MARK:- Recorder Delegate
    
    func didFinishRecording(successful: Bool) {
        tempURL = NSURL(fileURLWithPath: tempPath)
        self.resetWaveform()
        self.generateWaveform()
        self.waveformButton.enabled = true
        var error: NSError?
        var audioSession = AVAudioSession.sharedInstance()
        audioSession.setCategory(AVAudioSessionCategoryPlayback, error: nil)
        audioSession.setActive(true, error: nil)
        audioPlayer = AVAudioPlayer(contentsOfURL: tempURL, error: &error)
        audioPlayer?.delegate = self
        if let err = error {
            println("audioPlayer error: \(err.localizedDescription)")
        }
        captureButton.layer.removeAllAnimations()
        captureButton.enabled = false
        saveButton.enabled = true
        view.addSubview(textInputBar)
        textInputBar.textView.placeholder = "Enter title for the media"
        textInputBar.textView.userInteractionEnabled = true
        textInputBar.textView.becomeFirstResponder()
        locationManager.startUpdatingLocation()
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
    
    // MARK:- Location Manager
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if let location: CLLocation = locations.last as? CLLocation {
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
            locationManager.stopUpdatingLocation()
            mapView.removeAnnotations(mapView.annotations)
        }
        
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let span = MKCoordinateSpanMake(0.025, 0.025)
        let region = MKCoordinateRegion(center: location.coordinate, span: span)
        mapView.centerCoordinate = location.coordinate
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        let alert = UIAlertController(
            title: "Error Accessing Location",
            message: "Please open settings and verify that the location access for this app is set to \n'While Using the App'. Also, make sure that the location services is turned on.",
            preferredStyle: UIAlertControllerStyle.Alert)
        let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil)
        let openSettingsAction = UIAlertAction(title: "Open Settings", style: .Default) { (action) in
            if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                UIApplication.sharedApplication().openURL(url)
            }
        }
        alert.addAction(cancelAction)
        alert.addAction(openSettingsAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }

}