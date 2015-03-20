//
//  XCCopyActiveDocumentPathAction.m
//  XCActionBar
//
//  Created by Pedro Gomes on 20/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCCopyActiveDocumentPathAction.h"

#import "XCUtils.h"
#import "XCIDEContext.h"
#import "XCIDEHelper.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
NSString *XCDocumentFilePathFormatName(XCDocumentFilePathFormat format) 
{
    switch (format) {
        case XCDocumentFilePathFormatURL:       return @"file://...";
        case XCDocumentFilePathFormatPOSIX:     return @"POSIX";
        case XCDocumentFilePathFormatTerminal:  return @"POSIX escaped";

        default: assert(false); // neve reached
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCCopyActiveDocumentPathAction ()

@property (nonatomic, readwrite) XCDocumentFilePathFormat format;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCCopyActiveDocumentPathAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithFormat:(XCDocumentFilePathFormat)format
{
    if((self = [super init])) {
        self.title    = [NSString stringWithFormat:@"Copy file path to pasteboard %@", XCDocumentFilePathFormatName(format)];
        self.subtitle = @"Copies active document's file path to pasteboard";
        self.format   = format;
        self.enabled  = YES;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context
{
    if([context sourceCodeDocument] == nil) return NO;
    
    NSURL *fileURL         = [context sourceCodeDocument].fileURL;
    NSString *formattedURL = [self formatURL:fileURL format:self.format];
    
    return [context copyContentsToPasteboard:formattedURL];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSString *)formatURL:(NSURL *)fileURL format:(XCDocumentFilePathFormat)format
{
    switch (format) {
        case XCDocumentFilePathFormatURL:       return [fileURL absoluteString];
        case XCDocumentFilePathFormatPOSIX:     return [fileURL path];
        case XCDocumentFilePathFormatTerminal:  return XCEscapedTerminalPOSIXPath([fileURL path]);
            
        default: assert(false); // never reached
            break;
    }
}

@end
