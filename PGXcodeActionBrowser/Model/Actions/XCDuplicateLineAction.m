//
//  XCDuplicateLineAction.m
//  XCXcodeActionBrowser
//
//  Created by Pedro Gomes on 17/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCDuplicateLineAction.h"

#import "XCIDEContext.h"
#import "XCIDEHelper.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCDuplicateLineAction ()

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCDuplicateLineAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)init
{
    if((self = [super init])) {
        self.title        = @"Duplicate Lines";
        self.subtitle     = @"Duplicates the selected line(s)";
        self.argumentHint = @"Number of times to duplicate (number > 0)";
        self.enabled      = YES;
    }
    return self;
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
    return [self parseArguments:arguments repeatCount:NULL];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context
{
    return [self duplicateSelectedLinesInContext:context];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context arguments:(NSString *)arguments
{
    NSUInteger repeatCount = 0;
    BOOL validArguments    = [self parseArguments:arguments repeatCount:&repeatCount];
    
    XCReturnFalseUnless(validArguments == YES);
    
    for(int i = 0; i < repeatCount; i++) {
        [self duplicateSelectedLinesInContext:context];
    }
    return YES;
}

#pragma mark - Helpers

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)parseArguments:(NSString *)arguments repeatCount:(out NSUInteger *)repeatCount
{
    arguments = [arguments stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSRegularExpression *expression = [[NSRegularExpression alloc] initWithPattern:@"^\\d+$"
                                                                           options:(NSRegularExpressionCaseInsensitive | NSRegularExpressionAnchorsMatchLines)
                                                                             error:nil];
    
    BOOL argumentIsValid = ([expression numberOfMatchesInString:arguments options:0 range:NSMakeRange(0, arguments.length)] > 0);
    XCReturnFalseUnless(argumentIsValid);
    
    argumentIsValid = (arguments.integerValue > 0);
    XCReturnFalseUnless(argumentIsValid);

    if(repeatCount != NULL) {
        *repeatCount = arguments.integerValue;
    }
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)duplicateSelectedLinesInContext:(id<XCIDEContext>)context
{
    NSTextView *textView = context.sourceCodeTextView;
    
    NSRange rangeForSelectedText  = [context retrieveTextSelectionRange];
    NSRange lineRangeForSelection = [textView.string lineRangeForRange:rangeForSelectedText];
    
    __block NSUInteger lineCount = 0;
    
    NSString *selectedLineText = [textView.string substringWithRange:lineRangeForSelection];
    [selectedLineText enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        lineCount++;
    }];
    
    [textView.textStorage beginEditing];
    
    NSString *stringToDuplicate = [[textView.textStorage string] substringWithRange:lineRangeForSelection];
    
    NSRange rangeOfDuplicatedText = NSMakeRange(lineRangeForSelection.location, lineRangeForSelection.length);
    [textView setSelectedRange:NSMakeRange(lineRangeForSelection.location, 0)];
    [textView insertText:stringToDuplicate];
    
    XCExecuteIf(lineCount > 1, [textView setSelectedRange:rangeOfDuplicatedText]);
    
    //    [context.sourceCodeDocument.textStorage indentCharacterRange:rangeOfDuplicatedText
    //                                                     undoManager:context.sourceCodeDocument.undoManager];
    
    [textView.textStorage endEditing];
    
    return YES;
}

@end
