//
//  RecorderViewController.swift
//  MARA Publisher
//
//  Created by Shree Raj Shrestha on 8/4/15.
//  Copyright (c) 2015 Shree Raj Shrestha. All rights reserved.
//

import UIKit
import AVFoundation

protocol RecorderDelegate {
    func didFinishRecording(successful: Bool)
}

class RecorderViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate, FDWaveformViewDelegate {

    @IBOutlet weak var waveform: FDWaveformView!
    @IBOutlet weak var recordStopPlayPauseButton: UIButton!
    @IBOutlet weak var useAudioButton: UIBarButtonItem!
    @IBOutlet weak var retakeButton: UIBarButtonItem!
    @IBOutlet weak var waveformLeft: NSLayoutConstraint!
    @IBOutlet weak var waveformRight: NSLayoutConstraint!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    internal var delegate: RecorderDelegate?
    internal var filePath = NSString()
    
    private var audioPlayer: AVAudioPlayer?
    private var audioRecorder: AVAudioRecorder?
    private var fileURL: NSURL?
    private var timer: NSTimer?
    
    private var state = NSString()
    private var fileManager = NSFileManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        state = "record"
        useAudioButton.enabled = false
        retakeButton.enabled = false
        activityIndicator.hidden = true
        recordStopPlayPauseButton.setImage(UIImage(named: "record"), forState: UIControlState.Normal)
        fileURL = NSURL(fileURLWithPath: filePath as String)!
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var screenSize: CGSize = UIScreen.mainScreen().bounds.size as CGSize
        
        if screenSize.height > screenSize.width {
            waveformLeft.constant = 0
            waveformRight.constant = waveformLeft.constant
        }
        else {
            waveformLeft.constant = (screenSize.width - (screenSize.height*4/3) + 50 ) / 2.0
            waveformRight.constant = waveformLeft.constant
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            let progressSample = UInt((currentPlayTime! + 0.010) * 44100.00)
            self.waveform.progressSamples = progressSample
        })
    }
    
    func resetWaveform() {
        self.timer?.invalidate()
        waveform.progressSamples = 0.0 as UInt!
    }
    
    @IBAction func cancelButtonPressed(sender: UIBarButtonItem) {
        self.deactivateAudioSession()
        self.navigationController?.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func useAudioButtonPressed(sender: UIBarButtonItem) {
        if audioPlayer?.playing == true {
            audioPlayer?.stop()
        }
        if audioRecorder?.recording == true {
            audioRecorder?.stop()
        }
        self.deactivateAudioSession()
        self.delegate?.didFinishRecording(true)
        self.navigationController?.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func recordStopPlayPauseButtonPressed(sender: UIButton) {
        switch state {
            
        case "record":
            activityIndicator.hidden = false
            activityIndicator.startAnimating()
            recordStopPlayPauseButton.setImage(UIImage(named: "stop"), forState: UIControlState.Normal)
            var audioSession = AVAudioSession.sharedInstance()
            audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, error: nil)
            audioSession.setActive(true, error: nil)
            
            let recordSettings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 2 as NSNumber,
                AVEncoderAudioQualityKey: AVAudioQuality.High.rawValue,
                ]
            var error: NSError?
            audioRecorder = AVAudioRecorder(URL: fileURL, settings: recordSettings as [NSObject : AnyObject], error: &error)
            if let err = error {
                println("audioRecorder error: \(err.localizedDescription)")
            } else {
                audioRecorder?.delegate = self
                audioRecorder?.meteringEnabled = true
                audioRecorder?.prepareToRecord()
                audioRecorder?.record()
                state = "recording"
            }
                
        case "recording":
            activityIndicator.stopAnimating()
            activityIndicator.hidden = true
            useAudioButton.enabled = true
            retakeButton.enabled = true
            recordStopPlayPauseButton.setImage(UIImage(named: "play"), forState: UIControlState.Normal)
            audioRecorder?.stop()
            self.deactivateAudioSession()
            
        case "stopped":
            var error: NSError?
            var audioSession = AVAudioSession.sharedInstance()
            audioSession.setCategory(AVAudioSessionCategoryPlayback, error: nil)
            audioSession.setActive(true, error: nil)
            audioPlayer = AVAudioPlayer(contentsOfURL: fileURL, error: &error)
            audioPlayer?.delegate = self
            if let err = error {
                println("audioPlayer error: \(err.localizedDescription)")
            } else {
                self.timer = NSTimer.scheduledTimerWithTimeInterval(0.001, target: self, selector: "updateWaveform", userInfo: nil, repeats: true)
                audioPlayer?.play()
                state = "playing"
                recordStopPlayPauseButton.setImage(UIImage(named: "pause"), forState: UIControlState.Normal)
            }
                
        case "playing":
            recordStopPlayPauseButton.setImage(UIImage(named: "play"), forState: UIControlState.Normal)
            audioPlayer?.pause()
            state = "paused"
                
        case "paused":
            recordStopPlayPauseButton.setImage(UIImage(named: "pause"), forState: UIControlState.Normal)
            audioPlayer?.play()
            state = "playing"
                
        default:
            state = "record"
            
        }
    }
    
    @IBAction func retakeButtonPressed(sender: UIBarButtonItem) {
        self.resetWaveform()
        self.deactivateAudioSession()
        recordStopPlayPauseButton.setImage(UIImage(named: "record"), forState: UIControlState.Normal)
        audioRecorder = nil
        audioPlayer = nil
        fileManager.removeItemAtPath(filePath as String, error: nil)
        useAudioButton.enabled = false
        retakeButton.enabled = false
        state = "record"
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - Audio Recorder
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder!, successfully flag: Bool) {
        audioRecorder = nil
        self.resetWaveform()
        self.generateWaveform()
        state = "stopped"
    }
    
    func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder!, error: NSError!) {
        println("Audio Record Encode Error: \(error.localizedDescription)")
        state = "record"
        useAudioButton.enabled = false
        retakeButton.enabled = false
        recordStopPlayPauseButton.setImage(UIImage(named: "record"), forState: UIControlState.Normal)
    }
    
    // MARK: - Audio Player Delegate
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        recordStopPlayPauseButton.setImage(UIImage(named: "play"), forState: UIControlState.Normal)
        deactivateAudioSession()
        self.resetWaveform()
        state = "stopped"
    }
    
    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer!, error: NSError!) {
        println("Audio Play Decode Error: \(error.localizedDescription)")
    }
    
    // MARK: - FDWaveformViewDelegate
    
    func waveformViewWillRender(waveformView: FDWaveformView!) {
    }
    
    func waveformViewDidRender(waveformView: FDWaveformView!) {
        UIView.animateWithDuration(0.001, animations: {
            self.waveform.alpha = 0.95
        })
    }


}
