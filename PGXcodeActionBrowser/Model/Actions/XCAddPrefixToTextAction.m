//
//  XCAddPrefixToTextAction.m
//  XCActionBar
//
//  Created by Pedro Gomes on 28/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCAddPrefixToTextAction.h"

#import "XCIDEContext.h"
#import "XCIDEHelper.h"
#import "XCTextSnippetHelper.h"

////////////////////////////////////////////////////////////////////////////////
// REVIEW: move to internal/private header
////////////////////////////////////////////////////////////////////////////////
@interface XCSurroundWithAction ()

- (BOOL)surroundTextSelectionInContext:(id<XCIDEContext>)context withPrefix:(NSString *)prefix andSuffix:(NSString *)suffix;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCAddPrefixToTextAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)init
{
    NSDictionary *spec = @{XCSurroundWithActionIdentifierKey: @"XCAddPrefixToTextAction",
                           XCSurroundWithActionTitleKey: @"",
                           XCSurroundWithActionSummaryKey: @"",
                           XCSurroundWithActionPrefixKey: @"",
                           XCSurroundWithActionSuffixKey: @""};
    if((self = [super initWithSpec:spec])) {
        self.title    = NSLocalizedString(@"Add prefix to text", @"");
        self.subtitle = NSLocalizedString(@"Adds prefix from the pasteboard to the selected text", @"");
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context
{
    NSString *prefix = [context retrievePasteboardTextContents];
    
    return [self surroundTextSelectionInContext:context withPrefix:prefix andSuffix:@""];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context arguments:(NSString *)arguments
{
    return NO;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)validateArgumentsWithContext:(id<XCIDEContext>)context arguments:(NSString *)arguments
{
    return NO;
}

@end
