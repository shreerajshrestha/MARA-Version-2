//
//  AddMediaViewController.swift
//  MARA for iPhone
//
//  Created by Shree Raj Shrestha on 7/27/15.
//  Copyright (c) 2015 Shree Raj Shrestha. All rights reserved.
//

import UIKit
import MobileCoreServices

class AddMediaViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var titleText = String()
    var mediaType = String()
    var mediaURL = NSURL()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = titleText
    }
    
    func showCamera() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            var camera = UIImagePickerController()
            camera.sourceType = UIImagePickerControllerSourceType.Camera
            camera.allowsEditing = false
            camera.delegate = self
            
            if mediaType == "image" {
                camera.mediaTypes = [kUTTypeImage]
            } else if mediaType == "video" {
                camera.mediaTypes = [kUTTypeMovie]
            }
            
            self.presentViewController(camera, animated: true, completion: nil)
        }
    }
    
    func saveCameraCapture() {
        
    }
    
    @IBAction func cancelButtonPressed(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func addButtonPressed(sender: UIBarButtonItem) {
        if mediaType == "recording" {
            // Show Recorder
        } else {
            showCamera()
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
    
    // MARK: - Image Picker Controller
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        mediaURL = info[UIImagePickerControllerMediaURL] as! NSURL
        println(mediaURL)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }

}
