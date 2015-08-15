//
//  ViewController.m
//  fileupload
//
//  Created by Shree Raj Shrestha on 8/7/15.
//  Copyright (c) 2015 Shree Raj Shrestha. All rights reserved.
//

#import "FTPUploader.h"
#include <CFNetwork/CFNetwork.h>

enum {
    kSendBufferSize = 32768
};

@interface FTPUploader () <NSStreamDelegate, NSURLConnectionDataDelegate>
@property (nonatomic, strong) NSURL *ftpURL;
@property (nonatomic, assign, readonly ) uint8_t *buffer;
@property (nonatomic, assign, readwrite) size_t bufferOffset;
@property (nonatomic, assign, readwrite) size_t bufferLimit;
@property (nonatomic, assign, readwrite) unsigned long long bytesTransferred;
@property (nonatomic, assign, readwrite) unsigned long long fileSize;
@end

@implementation FTPUploader
{
    uint8_t _buffer[kSendBufferSize];
    NSOutputStream *networkStream;
    NSInputStream *fileStream;
}

- (uint8_t *)buffer
{
    return self->_buffer;
}

- (void)dealloc
{
    networkStream = nil;
    fileStream = nil;
    self.ftpURL = nil;
    self.bufferLimit = 0;
    self.bufferOffset = 0;
}

- (void) setSourceFilePath:(NSString *)sourceFilePath
{
    _sourceFilePath = sourceFilePath;
}

- (void) setFTPURL:(NSString *)FTPURL {
    _FTPURL = FTPURL;
}

- (void) setFTPUsername:(NSString *)FTPUsername {
    _FTPUsername = FTPUsername;
}

- (void) setFTPPassword:(NSString *)FTPPassword {
    _FTPPassword = FTPPassword;
}

- (void) stopUpload
{
    networkStream.delegate = nil;
    [networkStream close];
    [networkStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

    networkStream = nil;
    
    [fileStream close];
    fileStream = nil;
}

- (NSURL *)smartURLForString:(NSString *)str
{
    NSURL *     result;
    NSString *  trimmedStr;
    NSRange     schemeMarkerRange;
    NSString *  scheme;
    
    assert(str != nil);
    result = nil;
    
    trimmedStr = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ( (trimmedStr != nil) && ([trimmedStr length] != 0) ) {
        schemeMarkerRange = [trimmedStr rangeOfString:@"://"];
        
        if (schemeMarkerRange.location == NSNotFound) {
            result = [NSURL URLWithString:[NSString stringWithFormat:@"ftp://%@", trimmedStr]];
        } else {
            scheme = [trimmedStr substringWithRange:NSMakeRange(0, schemeMarkerRange.location)];
            assert(scheme != nil);
            
            if ( ([scheme compare:@"ftp"  options:NSCaseInsensitiveSearch] == NSOrderedSame) ) {
                result = [NSURL URLWithString:trimmedStr];
            } else {
                // It looks like this is some unsupported URL scheme.
            }
        }
    }
    return result;
}

- (void) startUpload
{
    _fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:_sourceFilePath error:nil] fileSize];
    
    // Creating the source file stream
    assert(fileStream == nil);
    fileStream = [NSInputStream inputStreamWithFileAtPath:_sourceFilePath];
    [fileStream open];
    
    // Creating ftp url
    NSURL *ftpURL = [self smartURLForString:_FTPURL];
    ftpURL = CFBridgingRelease(
                               CFURLCreateCopyAppendingPathComponent(NULL,
                                                                     (__bridge CFURLRef) ftpURL,
                                                                     (__bridge CFStringRef) [_sourceFilePath lastPathComponent],
                                                                     false)
                               );
    _ftpURL = ftpURL;
    
    // Preparing network stream for ftp
    assert(networkStream == nil);
    networkStream = CFBridgingRelease(
                                       CFWriteStreamCreateWithFTPURL(NULL,
                                                                     (__bridge CFURLRef) ftpURL)
                                       );
    
    // Setting up ftp details for network stream
    BOOL success;
    success = [networkStream setProperty:_FTPUsername forKey:(id)kCFStreamPropertyFTPUserName];
    assert(success);
    success = [networkStream setProperty:_FTPPassword forKey:(id)kCFStreamPropertyFTPPassword];
    assert(success);
    
    networkStream.delegate = self;
    [networkStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [networkStream open];
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
#pragma unused(aStream)
    assert(aStream == networkStream);
    
    switch (eventCode) {
            
        case NSStreamEventOpenCompleted: {
        } break;
            
        case NSStreamEventHasBytesAvailable: {
            assert(NO);
        } break;
            
        case NSStreamEventHasSpaceAvailable: {
            [self.delegate updateProgress:_bytesTransferred * 1.00 /_fileSize];
            if (_bufferOffset == _bufferLimit) {
                NSInteger   bytesRead;
                bytesRead = [fileStream read:_buffer maxLength:kSendBufferSize];
                if (bytesRead == -1) {
                    _bytesTransferred = 0;
                    [self.delegate uploadDidFailWithError:@"Source File Open Error!"];
                    [self stopUpload];
                } else if (bytesRead == 0) {
                    _bytesTransferred = 0;
                    [self.delegate uploadedSuccessfullyToURL:_ftpURL];
                    [self stopUpload];
                } else {
                    _bufferOffset = 0;
                    _bufferLimit  = bytesRead;
                }
            }
            
            if (_bufferOffset != _bufferLimit) {
                NSInteger   bytesWritten;
                bytesWritten = [networkStream write:&_buffer[_bufferOffset] maxLength:_bufferLimit - _bufferOffset];
                assert(bytesWritten != 0);
                if (bytesWritten == -1) {
                    _bytesTransferred = 0;
                    [self.delegate uploadDidFailWithError:@"FTP Server Write Error!"];
                    [self stopUpload];
                } else {
                    _bufferOffset += bytesWritten;
                    _bytesTransferred += bytesWritten;
                }
            }
        } break;
            
        case NSStreamEventErrorOccurred: {
            [self.delegate uploadDidFailWithError:@"Network Stream Open Error!"];
            [self stopUpload];
        } break;
            
        case NSStreamEventEndEncountered: {
            if (networkStream != nil) {
                [self stopUpload];
            }
        } break;
            
        default: {
            assert(NO);
        } break;
    }
}

@end
