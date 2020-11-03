//
//  ALTextInputUtilities.swift
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

internal func defaultNumberOfLines() -> CGFloat {
    if (UIDevice.isIPad()) {
        return 8;
    }
    if (UIDevice.isIPhone4()) {
        return 4;
    }
    
    return 6;
}

internal extension UIDevice {
    internal class func isIPad() -> Bool {
        return UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad
    }
    
    internal class func isIPhone() -> Bool {
        return UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone
    }
    
    internal class func isIPhone4() -> Bool {
        return UIDevice.isIPhone() && UIScreen.mainScreen().bounds.size.height < 568.0
    }
    
    internal class func floatVersion() -> Float {
        return (UIDevice.currentDevice().systemVersion as NSString).floatValue
    }
}
