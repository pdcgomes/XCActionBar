//
//  XCCopyActiveDocumentDirectoryAction.m
//  XCActionBar
//
//  Created by Pedro Gomes on 20/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCCopyActiveDocumentDirectoryAction.h"

#import "XCUtils.h"
#import "XCIDEContext.h"
#import "XCIDEHelper.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCCopyActiveDocumentDirectoryAction ()

@property (nonatomic, readwrite) XCDocumentFilePathFormat format;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCCopyActiveDocumentDirectoryAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithFormat:(XCDocumentFilePathFormat)format
{
    if((self = [super init])) {
        self.title    = [NSString stringWithFormat:@"Copy directory to pasteboard %@", XCDocumentFilePathFormatName(format)];
        self.subtitle = @"Copies active document's base path to pasteboard";
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

    BOOL success =[context copyContentsToPasteboard:formattedURL];
    if(success) {
        [context sendActionExecutionConfirmationWithInfo:@{XCActionInfoTitleKey:    @"Document's path copied to clipboard",
                                                           XCActionInfoSubtitleKey: @"",
                                                           XCActionInfoSummaryKey:  @""}];
    }

    return success;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSString *)formatURL:(NSURL *)fileURL format:(XCDocumentFilePathFormat)format
{
    switch (format) {
        case XCDocumentFilePathFormatURL:       return [[fileURL absoluteString] stringByDeletingLastPathComponent];
        case XCDocumentFilePathFormatPOSIX:     return [[fileURL path] stringByDeletingLastPathComponent];
        case XCDocumentFilePathFormatTerminal:  return XCEscapedTerminalPOSIXPath([[fileURL path] stringByDeletingLastPathComponent]);
            
        default: assert(false); // never reached
            break;
    }
}

@end
