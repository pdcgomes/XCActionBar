//
//  XCDuplicateLineAction.m
//  PGXcodeActionBrowser
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

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *hint;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCDuplicateLineAction

@synthesize title, hint, subtitle;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)init
{
    if((self = [super init])) {
        self.title    = @"Duplicate Line(s)";
        self.subtitle = @"";
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

    [textView.textStorage beginEditing];
    
    NSString *stringToDuplicate = [[textView.textStorage string] substringWithRange:lineRangeForSelection];
    
    NSRange rangeOfDuplicatedText = NSMakeRange(lineRangeForSelection.location + 1, lineRangeForSelection.length);
    [textView setSelectedRange:NSMakeRange(lineRangeForSelection.location + 1, 0)];
    [textView insertText:stringToDuplicate];
    [context.sourceCodeDocument.textStorage indentCharacterRange:rangeOfDuplicatedText
                                                     undoManager:context.sourceCodeDocument.undoManager];
    
    [textView.textStorage endEditing];
    
    return YES;
}

@end
