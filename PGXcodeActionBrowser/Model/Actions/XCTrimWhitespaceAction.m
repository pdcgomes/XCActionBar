//
//  XCTrimWhitespaceAction.m
//  XCActionBar
//
//  Created by Pedro Gomes on 20/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

//([^\s])[\s]+$
#import "XCTrimWhitespaceAction.h"

#import "XCIDEContext.h"
#import "XCIDEHelper.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
NSString *const XCTrimLeadingWhitespacePattern  = @"^[\\s]+";
NSString *const XCTrimTrailingWhitespacePattern = @"([^\\s])[\\s]+$";
NSString *const XCTrimWhitespacePattern         = (@"^[\\s]+"              // XCTrimLeadingWhitespacePattern
                                                   @"|"                     // or
                                                   @"([^\\s])[\\s]+$");  // XCTrimTrailingWhitespacePattern

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
NSString *XCTrimWhitespaceActionTitleFromBehavior(XCTrimWhitespaceBehavior behavior)
{
    switch (behavior) {
        case XCTrimWhitespaceBehaviorLeading:               return @"Trim Leading Whitespace";
        case XCTrimWhitespaceBehaviorTrailing:              return @"Trim Trailing Whitespace";
        case XCTrimWhitespaceBehaviorLeadingAndTrailing:    return @"Trim Whitespace (leading/trailing)";
            
        default: assert(false); // never reached
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
NSString *XCTrimWhitespacePatternForBehavior(XCTrimWhitespaceBehavior behavior)
{
    switch (behavior) {
        case XCTrimWhitespaceBehaviorLeading:               return XCTrimLeadingWhitespacePattern;
        case XCTrimWhitespaceBehaviorTrailing:              return XCTrimTrailingWhitespacePattern;
        case XCTrimWhitespaceBehaviorLeadingAndTrailing:    return XCTrimWhitespacePattern;
            
        default: assert(false); // never reached
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCTrimWhitespaceAction ()

@property (nonatomic, readwrite) XCTrimWhitespaceBehavior behavior;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCTrimWhitespaceAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithBehavior:(XCTrimWhitespaceBehavior)behavior
{
    if((self = [super init])) {
        self.title    = XCTrimWhitespaceActionTitleFromBehavior(behavior);
        self.subtitle = @"Trims whitespace";
        self.enabled  = YES;
        
        self.behavior = behavior;
        
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context
{
    if(self.behavior == XCTrimWhitespaceBehaviorLeadingAndTrailing) return [self trimSelectionWithContext:context];
    else return [self trimSelectionWithPattern:XCTrimWhitespacePatternForBehavior(self.behavior) 
                                       context:context];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)trimSelectionWithContext:(id<XCIDEContext>)context
{
    NSTextView *textView = context.sourceCodeTextView;
    
    NSRange rangeForSelectedText = [context retrieveTextSelectionRange];
    NSMutableString *trimmedText = [textView.string substringWithRange:rangeForSelectedText].mutableCopy;
    
    BOOL trimmedLead  = [self trimText:trimmedText withPattern:XCTrimLeadingWhitespacePattern];
    BOOL trimmedTrail = [self trimText:trimmedText withPattern:XCTrimTrailingWhitespacePattern];
    
    if(trimmedLead == NO && trimmedTrail == NO) return NO;

    [textView.textStorage beginEditing];
    
    [context.sourceCodeDocument.textStorage replaceCharactersInRange:rangeForSelectedText 
                                                          withString:trimmedText
                                                     withUndoManager:context.sourceCodeDocument.undoManager];
    
    [textView.textStorage endEditing];

    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)trimSelectionWithPattern:(NSString *)pattern context:(id<XCIDEContext>)context
{
    NSTextView *textView = context.sourceCodeTextView;
    
    NSRange rangeForSelectedText  = [context retrieveTextSelectionRange];
    NSString *selectedText        = [textView.string substringWithRange:rangeForSelectedText];

    NSMutableString *transformedSelecedText = selectedText.mutableCopy;

    if([self trimText:transformedSelecedText withPattern:pattern] == NO) return NO;
    
    [textView.textStorage beginEditing];
    
    [context.sourceCodeDocument.textStorage replaceCharactersInRange:rangeForSelectedText 
                                                          withString:transformedSelecedText 
                                                     withUndoManager:context.sourceCodeDocument.undoManager];
    
    [textView.textStorage endEditing];
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)trimText:(NSMutableString *)text withPattern:(NSString *)pattern
{
    NSRegularExpression *expression = [[NSRegularExpression alloc] initWithPattern:pattern
                                                                           options:NSRegularExpressionAnchorsMatchLines
                                                                             error:nil];
    NSArray *matches = [expression matchesInString:text 
                                           options:0 
                                             range:NSMakeRange(0, text.length)];
    
    if(TRCheckIsEmpty(matches)) return NO;
    
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult *match, NSUInteger idx, BOOL *stop) {
        if(match.numberOfRanges == 0 || match.range.location == NSNotFound) return;
        if(match.numberOfRanges == 1) [text replaceCharactersInRange:match.range withString:@""];
        else {
            NSRange rangeForSubstitution = [match rangeAtIndex:1];
            NSString *substitution = [text substringWithRange:rangeForSubstitution];
            [text replaceCharactersInRange:match.range withString:substitution];
        }
    }];
    return YES;
}

@end
