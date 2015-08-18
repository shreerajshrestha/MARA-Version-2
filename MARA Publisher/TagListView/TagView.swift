//
//  TagView.swift
//  TagListViewDemo
//
//  Created by Dongyuan Liu on 2015-05-09.
//  Copyright (c) 2015 Ela. All rights reserved.
//

/*
The MIT License (MIT)

Copyright (c) 2015 LIU Dongyuan

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import UIKit

@IBDesignable
public class TagView: UIButton {
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    @IBInspectable var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.CGColor
        }
    }
    @IBInspectable var textColor: UIColor = UIColor.whiteColor() {
        didSet {
            setTitleColor(textColor, forState: UIControlState.Normal)
        }
    }
    @IBInspectable var paddingY: CGFloat = 2 {
        didSet {
            titleEdgeInsets.top = paddingY
            titleEdgeInsets.bottom = paddingY
        }
    }
    @IBInspectable var paddingX: CGFloat = 5 {
        didSet {
            titleEdgeInsets.left = paddingY
            titleEdgeInsets.right = paddingY
        }
    }
    
    @IBInspectable public var tagBackgroundColor: UIColor = UIColor.grayColor() {
        didSet {
            backgroundColor = tagBackgroundColor
        }
    }
    
    @IBInspectable public var tagSelectedBackgroundColor: UIColor = UIColor.redColor() {
        didSet {
            backgroundColor = selected ? tagSelectedBackgroundColor : tagBackgroundColor
        }
    }
    
    
    var textFont: UIFont = UIFont.systemFontOfSize(12) {
        didSet {
            titleLabel?.font = textFont
        }
    }
    
    override public var selected: Bool {
        didSet {
            if selected {
                backgroundColor = tagSelectedBackgroundColor
            } else {
                backgroundColor = tagBackgroundColor
            }
        }
    }
    
    /// Handles Tap (TouchUpInside)
    public var onTap: ((TagView) -> Void)?
    
    // MARK: - init
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupView()
    }
    
    init(title: String) {
        super.init(frame: CGRectZero)
        setTitle(title, forState: UIControlState.Normal)
        
        setupView()
    }
    
    private func setupView() {
        frame.size = intrinsicContentSize()
    }
    
    // MARK: - layout
    
    override public func intrinsicContentSize() -> CGSize {
        var size = titleLabel?.text?.sizeWithAttributes([NSFontAttributeName: textFont]) ?? CGSizeZero
        
        size.height = textFont.pointSize + paddingY * 2
        size.width += paddingX * 2
        
        return size
    }
}
