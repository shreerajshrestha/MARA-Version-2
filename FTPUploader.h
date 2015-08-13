//
//  ViewController.h
//  fileupload
//
//  Created by Shree Raj Shrestha on 8/7/15.
//  Copyright (c) 2015 Shree Raj Shrestha. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol FTPUploaderDelegate;

@interface FTPUploader : NSObject
@property (nonatomic, weak) id <FTPUploaderDelegate> delegate;
@property (nonatomic, strong) NSString *sourceFilePath;
@property (nonatomic, strong) NSString *FTPURL;
@property (nonatomic, strong) NSString *FTPUsername;
@property (nonatomic, strong) NSString *FTPPassword;
-(void) startUpload;
@end

@protocol FTPUploaderDelegate <NSObject>
@optional
- (void) uploadedSuccessfullyToURL:(NSURL *)URL;
- (void) uploadDidFailWithError:(NSString *)error;
- (void) updateProgress:(float)progress;
@end