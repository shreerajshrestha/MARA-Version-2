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
import MediaPlayer

class AddMediaViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var preview: UIView!
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var saveAsTextField: UITextField!
    @IBOutlet weak var tagsTextField: UITextField!
    @IBOutlet weak var latitudeTextField: UITextField!
    @IBOutlet weak var longitudeTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    
    var titleText = String()
    var mediaType = String()
    var fileManager = NSFileManager()
    var camera = UIImagePickerController()
    var videoPlayer: MPMoviePlayerController!
    var tempPath = String()
    var locationManager = CLLocationManager()
    var latitude = Double()
    var longitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = titleText
        camera.delegate = self
        locationManager.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        var screenSize: CGSize = UIScreen.mainScreen().bounds.size as CGSize
        contentViewHeight.constant = screenSize.width + 438
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
    
    func loadPreview() {
        switch mediaType {
            
        case "image":
            if let tempImage = UIImage(contentsOfFile: tempPath) {
                imagePreview.image = tempImage
            }
        case "video":
            var videoURL: NSURL! = NSURL(fileURLWithPath: tempPath)
            videoPlayer = MPMoviePlayerController(contentURL: videoURL)
            if let player = videoPlayer {
                var screenSize: CGSize = UIScreen.mainScreen().bounds.size as CGSize
                player.view.frame = CGRect(x: 0, y: 0, width: screenSize.width - 50, height: preview.frame.height)
                player.view.center.x = preview.center.x
                player.view.center.y = preview.center.y
                player.scalingMode = MPMovieScalingMode.AspectFit
                player.controlStyle = MPMovieControlStyle.Embedded
                player.movieSourceType = MPMovieSourceType.File
                player.play()
                player.pause()
                preview.addSubview(player.view)
            }
        default:
            println("Handle other cases")
        }
    }
    
    @IBAction func cancelButtonPressed(sender: UIBarButtonItem) {
        self.navigationController?.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func captureButtonPressed(sender: UIButton) {
        if mediaType == "recording" {
            // Show Recorder
        } else {
            showCamera()
        }
    }
    
    @IBAction func getLocationButtonTapped(sender: UIButton) {
        switch CLLocationManager.authorizationStatus() {
            
        case .NotDetermined:
            locationManager.requestWhenInUseAuthorization()
            
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
            tempPath = NSTemporaryDirectory().stringByAppendingString("temp.jpg")
            fileManager.removeItemAtPath(tempPath, error: nil)
            UIImageJPEGRepresentation(capturedImage, 1.0).writeToFile(tempPath, atomically: true)
        case "video":
            var capturedVideoURL: NSURL = info[UIImagePickerControllerMediaURL] as! NSURL
            tempPath = NSTemporaryDirectory().stringByAppendingString("temp.mp4")
            var tempURL: NSURL! = NSURL(fileURLWithPath: tempPath)
            fileManager.removeItemAtURL(tempURL, error: nil)
            fileManager.copyItemAtURL(capturedVideoURL, toURL: tempURL, error: nil)
        default:
            dismissViewControllerAnimated(true, completion: nil)
        }
        loadPreview()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
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
