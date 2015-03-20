//
//  XCCopyActiveDocumentPathAction.h
//  XCActionBar
//
//  Created by Pedro Gomes on 20/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCCustomAction.h"

// REVIEW: move enum and helpers to common header

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
typedef NS_ENUM(NSUInteger, XCDocumentFilePathFormat) {
    XCDocumentFilePathFormatURL = 0,
    XCDocumentFilePathFormatPOSIX,
    XCDocumentFilePathFormatTerminal,
};

FOUNDATION_EXPORT NSString *XCDocumentFilePathFormatName(XCDocumentFilePathFormat format);

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCCopyActiveDocumentPathAction : XCCustomAction

- (instancetype)initWithFormat:(XCDocumentFilePathFormat)format;

@end
