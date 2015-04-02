//
//  XCAddPrefixToLinesAction.m
//  XCXcodeActionBrowser
//
//  Created by Pedro Gomes on 16/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCAddPrefixToLinesAction.h"

#import "XCIDEContext.h"
#import "XCIDEHelper.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCAddPrefixToLinesAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)init
{
    if((self = [super init])) {
        self.title        = @"Add Prefix to Line(s)";
        self.subtitle     = @"Prepends pasteboard text contents to each selected line";
        self.argumentHint = NSLocalizedString(@"Enter the prefix", @"");

        self.enabled  = YES;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context
{
    NSString *prefix = [context retrievePasteboardTextContents];

    return [self addPrefixToLinesWithContext:context prefix:prefix];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context arguments:(NSString *)arguments
{
    return [self addPrefixToLinesWithContext:context prefix:arguments];
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

#pragma mark - Helpers

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)addPrefixToLinesWithContext:(id<XCIDEContext>)context prefix:(NSString *)prefix
{
    if(TRCheckIsEmpty(prefix) == YES) return NO;
    
    NSTextView *textView = context.sourceCodeTextView;
    
    NSRange rangeForSelectedText  = [context retrieveTextSelectionRange];
    NSRange lineRangeForSelection = [textView.string lineRangeForRange:rangeForSelectedText];
    
    NSMutableArray *lineComponents = [[textView.string substringWithRange:lineRangeForSelection] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]].mutableCopy;
    [lineComponents removeLastObject];
    
    NSMutableString *replacementString = [[NSMutableString alloc] init];
    
    for(NSString *line in lineComponents) {
        [replacementString appendString:prefix];
        [replacementString appendString:line];
        [replacementString appendString:@"\n"];
    }
    
    
    if([textView shouldChangeTextInRange:rangeForSelectedText replacementString:replacementString] == NO) {
        return NO;
    }
    
    [textView.textStorage beginEditing];
    
    [context.sourceCodeDocument.textStorage replaceCharactersInRange:rangeForSelectedText
                                                          withString:replacementString];
    
    [textView.textStorage endEditing];
    
    return YES;
}

@end
