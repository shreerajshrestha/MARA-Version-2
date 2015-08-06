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
    
    var delegate: RecorderDelegate?

    @IBOutlet weak var waveform: FDWaveformView!
    @IBOutlet weak var recordStopPlayPauseButton: UIButton!
    @IBOutlet weak var useAudioButton: UIBarButtonItem!
    @IBOutlet weak var retakeButton: UIBarButtonItem!
    
    var audioPlayer: AVAudioPlayer?
    var audioRecorder: AVAudioRecorder?
    var fileURL: NSURL?
    var timer: NSTimer?
    
    var state = NSString()
    var filePath = NSString()
    var fileManager = NSFileManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        state = "record"
        useAudioButton.enabled = false
        retakeButton.enabled = false
        recordStopPlayPauseButton.setTitle("Record", forState: UIControlState.Normal)
        fileURL = NSURL(fileURLWithPath: filePath as String)!
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
            let progressSample = UInt((currentPlayTime! + 0.065) * 44100.00)
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
            recordStopPlayPauseButton.setTitle("Stop", forState: UIControlState.Normal)
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
            useAudioButton.enabled = true
            retakeButton.enabled = true
            recordStopPlayPauseButton.setTitle("Play", forState: UIControlState.Normal)
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
                recordStopPlayPauseButton.setTitle("Pause", forState: UIControlState.Normal)
            }
                
        case "playing":
            recordStopPlayPauseButton.setTitle("Play", forState: UIControlState.Normal)
            audioPlayer?.pause()
            state = "paused"
                
        case "paused":
            recordStopPlayPauseButton.setTitle("Pause", forState: UIControlState.Normal)
            audioPlayer?.play()
            state = "playing"
                
        default:
            state = "record"
            
        }
    }
    
    @IBAction func retakeButtonPressed(sender: UIBarButtonItem) {
        recordStopPlayPauseButton.setTitle("Record", forState: UIControlState.Normal)
        audioRecorder = nil
        audioPlayer = nil
        fileManager.removeItemAtPath(filePath as String, error: nil)
        useAudioButton.enabled = false
        retakeButton.enabled = false
        state = "record"
        self.deactivateAudioSession()
        self.generateWaveform()
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
        recordStopPlayPauseButton.setTitle("Record", forState: UIControlState.Normal)
    }
    
    // MARK: - Audio Player Delegate
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        recordStopPlayPauseButton.setTitle("Play", forState: UIControlState.Normal)
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
        UIView.animateWithDuration(0.01, animations: {
            self.waveform.alpha = 1.00
        })
    }


}
