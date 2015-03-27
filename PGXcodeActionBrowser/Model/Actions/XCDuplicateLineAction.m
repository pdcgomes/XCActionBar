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
        self.title    = @"Duplicate Line(s)";
        self.subtitle = @"";
        self.enabled  = YES;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context
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
