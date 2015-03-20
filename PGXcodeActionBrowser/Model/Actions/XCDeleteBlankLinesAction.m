//
//  XCDeleteBlankLinesAction.m
//  XCActionBar
//
//  Created by Pedro Gomes on 20/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCDeleteBlankLinesAction.h"

#import "XCIDEContext.h"
#import "XCIDEHelper.h"

NSString *const XCEmptyLinePattern = @"^\\s*\\n";

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCDeleteBlankLinesAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)init
{
    if((self = [super init])) {
        self.title    = @"Delete empty lines";
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
    NSMutableString *selectedText = [textView.string substringWithRange:lineRangeForSelection].mutableCopy;
    
    NSRegularExpression *expression = [[NSRegularExpression alloc] initWithPattern:XCEmptyLinePattern options:NSRegularExpressionAnchorsMatchLines error:nil];
    NSArray *matches = [expression matchesInString:selectedText options:0 range:NSMakeRange(0, selectedText.length)];
    
    if(TRCheckIsEmpty(matches)) return NO;

    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult *match, NSUInteger idx, BOOL *stop) {
        [selectedText replaceCharactersInRange:match.range withString:@""];
    }];
    
    [textView.textStorage beginEditing];

    [textView insertText:selectedText replacementRange:lineRangeForSelection];
    
    [textView.textStorage endEditing];
    
    return YES;
}

@end
