//
//  ALKeyboardObservingView.swift
//  ALTextInputBar
//
//  Created by Alex Littlejohn on 2015/05/14.
//  Copyright (c) 2015 zero. All rights reserved.
//
/*
The MIT License (MIT)

Copyright (c) 2015 AlexLittlejohn

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import UIKit

public let ALKeyboardFrameDidChangeNotification = "ALKeyboardFrameDidChangeNotification"

public class ALKeyboardObservingView: UIView {

    private weak var observedView: UIView?
    private var defaultHeight: CGFloat = 44
    
    override public func intrinsicContentSize() -> CGSize {
        return CGSizeMake(UIViewNoIntrinsicMetric, defaultHeight)
    }
    
    public override func willMoveToSuperview(newSuperview: UIView?) {
        
        removeKeyboardObserver()
        if let _newSuperview = newSuperview {
            addKeyboardObserver(_newSuperview)
        }
        
        super.willMoveToSuperview(newSuperview)
    }
    
    public override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if object as? NSObject == superview && keyPath == keyboardHandlingKeyPath() {
            keyboardDidChangeFrame(superview!.frame)
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    public func updateHeight(height: CGFloat) {
        if UIDevice.floatVersion() < 8.0 {
            frame.size.height = height
            
            setNeedsLayout()
            layoutIfNeeded()
        }
        
        for c in constraints() {
            var constraint = c as! NSLayoutConstraint
            if constraint.firstAttribute == NSLayoutAttribute.Height && constraint.firstItem as! NSObject == self {
                constraint.constant = height < defaultHeight ? defaultHeight : height
            }
        }
    }
    
    private func keyboardHandlingKeyPath() -> String {
        if UIDevice.floatVersion() >= 8.0 {
            return "center"
        } else {
            return "frame"
        }
    }
    
    private func addKeyboardObserver(newSuperview: UIView) {
        observedView = newSuperview
        newSuperview.addObserver(self, forKeyPath: keyboardHandlingKeyPath(), options: NSKeyValueObservingOptions.New, context: nil)
    }
    
    private func removeKeyboardObserver() {
        if observedView != nil {
            observedView!.removeObserver(self, forKeyPath: keyboardHandlingKeyPath())
            observedView = nil
        }
    }
    
    private func keyboardDidChangeFrame(frame: CGRect) {
        let userInfo = [UIKeyboardFrameEndUserInfoKey: NSValue(CGRect:frame)]
        NSNotificationCenter.defaultCenter().postNotificationName(ALKeyboardFrameDidChangeNotification, object: nil, userInfo: userInfo)
    }
    
    deinit {
        removeKeyboardObserver()
    }
}
