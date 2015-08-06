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

class AddMediaViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate, AVAudioPlayerDelegate, RecorderDelegate, FDWaveformViewDelegate {
    
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var videoContainer: UIView!
    @IBOutlet weak var waveform: FDWaveformView!
    @IBOutlet weak var waveformButton: UIButton!
    @IBOutlet weak var saveAsTextField: UITextField!
    @IBOutlet weak var tagsTextField: UITextField!
    @IBOutlet weak var latitudeTextField: UITextField!
    @IBOutlet weak var longitudeTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    
    var audioPlayer: AVAudioPlayer?
    var timer: NSTimer?
    var tempURL: NSURL?
    var fileURL: NSURL?
    
    var mediaType = String()
    var tempPath = String()
    var documentsFolder = String()
    var fileManager = NSFileManager()
    var camera = UIImagePickerController()
    var locationManager = CLLocationManager()
    var latitude = Double()
    var longitude = Double()
    
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        camera.delegate = self
        locationManager.delegate = self
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
        let documentsDirectory = paths.objectAtIndex(0) as! NSString
        
        switch mediaType {
        case "image":
            imagePreview.hidden = false
            imagePreview.userInteractionEnabled = true
            tempPath = NSTemporaryDirectory().stringByAppendingString("temp.jpg")
            documentsFolder = documentsDirectory.stringByAppendingString("/Images/")
        case "video":
            videoContainer.hidden = false
            videoContainer.userInteractionEnabled = true
            tempPath = NSTemporaryDirectory().stringByAppendingString("temp.mp4")
            documentsFolder = documentsDirectory.stringByAppendingString("/Videos/")
        case "recording":
            waveform.hidden = false
            tempPath = NSTemporaryDirectory().stringByAppendingString("temp.m4a")
            documentsFolder = documentsDirectory.stringByAppendingString("/Recordings/")
        default:
            videoContainer.hidden = true
            imagePreview.hidden = true
            waveform.hidden = true
        }
        
        var error: NSError?
        if !fileManager.fileExistsAtPath(documentsFolder as String) {
            fileManager.createDirectoryAtPath(documentsFolder as String, withIntermediateDirectories: false, attributes: nil, error: &error)
        }
        
        if let err = error {
            println("fileManager error: \(err.localizedDescription)")
        }
        
        tempURL = NSURL.fileURLWithPath(tempPath)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        var screenSize: CGSize = UIScreen.mainScreen().bounds.size as CGSize
        contentViewHeight.constant = screenSize.width*3/4.0 + 425
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func keyboardWillShow(notification: NSNotification) {
    }
    
    func keyboardWillHide(notification: NSNotification) {
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
            let progressSample = UInt((currentPlayTime! + 0.065) * 44100.00)
            self.waveform.progressSamples = progressSample
        })
    }
    
    func resetWaveform() {
        self.timer?.invalidate()
        waveform.progressSamples = 0.0 as UInt!
    }
    
    func validateInputFields() -> Bool {
        if saveAsTextField.text == "" {
            return false
        }
        if tagsTextField.text == "" {
            return false
        }
        if descriptionTextView.text == "" {
            return false
        }
        if latitudeTextField.text == "" || longitudeTextField.text == "" {
            return false
        }
        return fileManager.fileExistsAtPath(tempPath)
    }
    
    @IBAction func cancelButtonPressed(sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Cancel Save?", message: "Any captured media and input fields will be cleared.", preferredStyle: UIAlertControllerStyle.Alert)
        let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: nil)
        let yesAction = UIAlertAction(title: "Yes", style: .Destructive) { (action) in
            self.navigationController?.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        alert.addAction(noAction)
        alert.addAction(yesAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }

    @IBAction func captureButtonPressed(sender: UIButton) {
        if mediaType == "recording" {
            let recorderNC = self.storyboard?.instantiateViewControllerWithIdentifier("recorderNC") as! UINavigationController
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
            waveformButton.setTitle("Pause", forState: UIControlState.Normal)
            self.timer = NSTimer.scheduledTimerWithTimeInterval(0.001, target: self, selector: "updateWaveform", userInfo: nil, repeats: true)
            audioPlayer?.play()
        }
        else {
            waveformButton.setTitle("Play", forState: UIControlState.Normal)
            audioPlayer?.pause()
        }
        
    }
    
    @IBAction func getLocationButtonTapped(sender: UIButton) {
        switch CLLocationManager.authorizationStatus() {
            
        case .NotDetermined:
            locationManager.requestWhenInUseAuthorization()
            locationManager.distanceFilter = kCLDistanceFilterNone
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            
        case .Restricted, .Denied:
            let alert = UIAlertController(title: "Location Access Disabled",
                message: "Location data is required to save media. Please open settings for this app and set location access to \n'While Using the App'.",
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
    }
    
    @IBAction func saveButtonTapped(sender: UIBarButtonItem) {
        
        if validateInputFields() {
            
            let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
            let documentsDirectory = paths.objectAtIndex(0) as! NSString
            
            let fileExists = false
            var fileName = NSString()
            
            do {
                let id = arc4random() % 999999999
                var pathComponents = NSArray()
                switch mediaType {
                case "image":
                    fileName = NSString(format: "%@%d.jpg", saveAsTextField.text.stringByReplacingOccurrencesOfString(" ", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil), id) as! String
                    pathComponents = NSArray(objects: documentsDirectory, "/Images/", fileName)
                case "video":
                    fileName = NSString(format: "%@%d.mp4", saveAsTextField.text.stringByReplacingOccurrencesOfString(" ", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil), id) as! String
                    pathComponents = NSArray(objects: documentsDirectory, "/Videos/", fileName)
                case "recording":
                    fileName = NSString(format: "%@%d.m4a", saveAsTextField.text.stringByReplacingOccurrencesOfString(" ", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil), id) as! String
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
            
            
            let now = NSDate()
            let formatter = NSDateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("MM/dd/yyyy HH:mm")
            let date = formatter.stringFromDate(now)
            
            switch mediaType {
            case "image":
                let imageObject = NSEntityDescription.insertNewObjectForEntityForName("ImageDB", inManagedObjectContext: self.managedObjectContext!) as! ImageDB
                imageObject.setValue(saveAsTextField.text as NSString, forKey: "name")
                imageObject.setValue(tagsTextField.text, forKey: "tags")
                imageObject.setValue(descriptionTextView.text, forKey: "descriptor")
                imageObject.setValue(longitude, forKey: "longitude")
                imageObject.setValue(latitude, forKey: "latitude")
                imageObject.setValue(date, forKey: "date")
                imageObject.setValue(fileName, forKey: "fileName")
                
            case "video":
                let videoObject = NSEntityDescription.insertNewObjectForEntityForName("VideoDB", inManagedObjectContext: self.managedObjectContext!) as! VideoDB
                videoObject.setValue(saveAsTextField.text as NSString, forKey: "name")
                videoObject.setValue(tagsTextField.text, forKey: "tags")
                videoObject.setValue(descriptionTextView.text, forKey: "descriptor")
                videoObject.setValue(longitude, forKey: "longitude")
                videoObject.setValue(latitude, forKey: "latitude")
                videoObject.setValue(date, forKey: "date")
                videoObject.setValue(fileName, forKey: "fileName")
                
            default:
                let recordingObject = NSEntityDescription.insertNewObjectForEntityForName("RecordingDB", inManagedObjectContext: self.managedObjectContext!) as! RecordingDB
                recordingObject.setValue(saveAsTextField.text as NSString, forKey: "name")
                recordingObject.setValue(tagsTextField.text, forKey: "tags")
                recordingObject.setValue(descriptionTextView.text, forKey: "descriptor")
                recordingObject.setValue(longitude, forKey: "longitude")
                recordingObject.setValue(latitude, forKey: "latitude")
                recordingObject.setValue(date, forKey: "date")
                recordingObject.setValue(fileName, forKey: "fileName")
            }
            
            self.managedObjectContext?.save(&error)
            if let err = error {
                println("managedObjectContext error: \(err.localizedDescription)")
            } else {
                let alert = UIAlertController(title: nil, message: "Successfully saved!", preferredStyle: UIAlertControllerStyle.Alert)
                let okAction = UIAlertAction(title: "Ok", style: .Default) { (action) in
                    self.navigationController?.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
                alert.addAction(okAction)
                self.presentViewController(alert, animated: false, completion: nil)
            }
        }
        else {
            let alert = UIAlertController(title: nil, message: "Please input all fields, get location data and capture media before saving!", preferredStyle: UIAlertControllerStyle.Alert)
            let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil)
            alert.addAction(okAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
            
            /*
        var dataPath = NSString()
            let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
            let documentsDirectory = paths.objectAtIndex(0) as! NSString
            dataPath = documentsDirectory.stringByAppendingString("/Images")
            dataPath = documentsDirectory.stringByAppendingString("/Videos")
            dataPath = documentsDirectory.stringByAppendingString("/Recordings")
            if fileManager.fileExistsAtPath(dataPath as String) {
                fileManager.createDirectoryAtPath(dataPath as String, withIntermediateDirectories: false, attributes: nil, error: nil)
            }
            
            var fileExists: Bool! = false
            var fileName = NSString()
            var fileURL = NSURL()
            
            do {
                let id = arc4random() % 999999999
                
                let fileName = NSString(format: "%@%d.jpg", saveAsTextField.text.stringByReplacingOccurrencesOfString(" ", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil), id) as! String
                
                var pathComponents = NSArray()
                switch mediaType {
                case "image":
                    pathComponents = NSArray(objects: documentsDirectory, "/Images/", fileName)
                case "video":
                    pathComponents = NSArray(objects: documentsDirectory, "/Videos/", fileName)
                case "recording":
                    pathComponents = NSArray(objects: documentsDirectory, "/Recordings/", fileName)
                default:
                    pathComponents = NSArray()
                }
                fileURL = NSURL.fileURLWithPathComponents(pathComponents as [AnyObject])!
            } while fileExists == true

            var error: NSError?
            fileManager.copyItemAtURL(tempURL!, toURL: fileURL, error: &error)
            if let err = error {
                println("fileManager error: \(err.localizedDescription)")
            }
*/
    }
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
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
            }
        case "video":
            var capturedVideoURL: NSURL = info[UIImagePickerControllerMediaURL] as! NSURL
            fileManager.removeItemAtURL(tempURL!, error: nil)
            fileManager.copyItemAtURL(capturedVideoURL, toURL: tempURL!, error: nil)
            let embededVC = self.childViewControllers[0] as! AVPlayerViewController
            let session = AVAudioSession.sharedInstance()
            session.setMode(AVAudioSessionModeMoviePlayback, error: nil)
            embededVC.player = AVPlayer(URL: tempURL)
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
        UIView.animateWithDuration(0.01, animations: {
            self.waveform.alpha = 1.00
        })
    }
    
    // MARK:- Recorder Delegate
    
    func didFinishRecording(successful: Bool) {
        tempURL = NSURL(fileURLWithPath: tempPath)
        self.resetWaveform()
        self.generateWaveform()
        self.waveformButton.hidden = false
        var error: NSError?
        var audioSession = AVAudioSession.sharedInstance()
        audioSession.setCategory(AVAudioSessionCategoryPlayback, error: nil)
        audioSession.setActive(true, error: nil)
        audioPlayer = AVAudioPlayer(contentsOfURL: tempURL, error: &error)
        audioPlayer?.delegate = self
        if let err = error {
            println("audioPlayer error: \(err.localizedDescription)")
        }
    }
    
    // MARK: - Audio Player
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        deactivateAudioSession()
        waveformButton.setTitle("Play", forState: UIControlState.Normal)
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
            latitudeTextField.text = "\(latitude)"
            longitudeTextField.text = "\(longitude)"
            locationManager.stopUpdatingLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        let alert = UIAlertController(
            title: "Error Accessing Location",
            message: "An unexpected error occured while accessing location data. Please open settings and verify that the location access for this app is set to \n'While Using the App'.",
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
