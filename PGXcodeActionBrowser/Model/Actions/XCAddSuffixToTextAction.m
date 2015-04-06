//
//  XCAddSuffixToTextAction.m
//  XCActionBar
//
//  Created by Pedro Gomes on 28/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCAddSuffixToTextAction.h"

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
@implementation XCAddSuffixToTextAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)init
{
    NSDictionary *spec = @{XCSurroundWithActionIdentifierKey: @"XCAddSuffixToTextAction",
                           XCSurroundWithActionTitleKey: @"",
                           XCSurroundWithActionSummaryKey: @"",
                           XCSurroundWithActionPrefixKey: @"",
                           XCSurroundWithActionSuffixKey: @""};
    if((self = [super initWithSpec:spec])) {
        self.title        = NSLocalizedString(@"Add suffix to text", @"");
        self.subtitle     = NSLocalizedString(@"Adds suffix from the pasteboard to the selected text", @"");
        self.argumentHint = NSLocalizedString(@"Enter the suffix", @"");
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context
{
    NSString *suffix = [context retrievePasteboardTextContents];
    
    return [self surroundTextSelectionInContext:context withPrefix:@"" andSuffix:suffix];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context arguments:(NSString *)arguments
{
    return [self surroundTextSelectionInContext:context withPrefix:@"" andSuffix:arguments];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)acceptsArguments
{
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)validateArgumentsWithContext:(id<XCIDEContext>)context arguments:(NSString *)arguments
{
    return (arguments.length > 0);
}

@end
