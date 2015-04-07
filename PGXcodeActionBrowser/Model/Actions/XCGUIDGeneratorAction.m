//
//  XCGUIDGeneratorAction.m
//  XCActionBar
//
//  Created by Pedro Gomes on 07/04/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCGUIDGeneratorAction.h"

#import "XCIDEContext.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCGUIDGeneratorAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)init
{
    if((self = [super init])) {
        self.title        = @"Generate UUID";
        self.subtitle     = @"Generates a globally unique identifier";
        self.enabled      = YES;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context
{
    NSString *uuid = [[NSUUID UUID] UUIDString];

    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] writeObjects:@[uuid]];
    
    [[context sourceCodeTextView] insertText:uuid];
    
    return YES;
}

@end
