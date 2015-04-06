//
//  XCReplaceSelectionAction.m
//  XCActionBar
//
//  Created by Pedro Gomes on 27/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCReplaceSelectionAction.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCReplaceSelectionAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithTextSelectionStorage:(id<XCTextSelectionStorage>)textSelectionStorage
{
    if((self = [super initWithTextSelectionStorage:textSelectionStorage])) {
        self.title           = NSLocalizedString(@"Replace selection", @"");
        self.subtitle        = NSLocalizedString(@"Replaces current selection with pasteboard contents", @""); // this will be applied to each non-contiguous range
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context
{
    return NO;
}

@end
