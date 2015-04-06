//
//  XCAddSuffixToLinesAction.m
//  XCXcodeActionBrowser
//
//  Created by Pedro Gomes on 16/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCAddSuffixToLinesAction.h"

#import "XCIDEContext.h"
#import "XCIDEHelper.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCAddSuffixToLinesAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)init
{
    if((self = [super init])) {
        self.title        = @"Add Suffix to Line(s)";
        self.subtitle     = @"Appends pasteboard text contents to each selected line";
        self.argumentHint = NSLocalizedString(@"Enter the suffix", @"");
        
        self.enabled  = YES;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context
{
    NSString *suffix = [context retrievePasteboardTextContents];
    
    return [self addSuffixWithContext:context suffix:suffix];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context arguments:(NSString *)arguments
{
    return [self addSuffixWithContext:context suffix:arguments];
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
- (BOOL)addSuffixWithContext:(id<XCIDEContext>)context suffix:(NSString *)suffix
{
    if(TRCheckIsEmpty(suffix) == YES) return NO;
    
    NSTextView *textView = context.sourceCodeTextView;
    
    NSRange rangeForSelectedText  = [context retrieveTextSelectionRange];
    NSRange lineRangeForSelection = [textView.string lineRangeForRange:rangeForSelectedText];
    
    NSMutableArray *lineComponents = [[textView.string substringWithRange:lineRangeForSelection] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]].mutableCopy;
    [lineComponents removeLastObject];
    
    NSMutableString *replacementString = [[NSMutableString alloc] init];
    
    for(NSString *line in lineComponents) {
        [replacementString appendString:line];
        [replacementString appendString:suffix];
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
