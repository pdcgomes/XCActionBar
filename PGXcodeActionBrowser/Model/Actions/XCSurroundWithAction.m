//
//  XCSurroundWithAction.m
//  XCXcodeActionBrowser
//
//  Created by Pedro Gomes on 16/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XCIDEContext.h"
#import "XCIDEHelper.h"
#import "XCSurroundWithAction.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
NSString *const XCSurroundWithActionIdentifierKey = @"XCSurroundWithActionIdentifier";
NSString *const XCSurroundWithActionTitleKey      = @"XCSurroundWithActionTitle";
NSString *const XCSurroundWithActionSummaryKey    = @"XCSurroundWithActionSummary";
NSString *const XCSurroundWithActionPrefixKey     = @"XCSurroundWithActionPrefix";
NSString *const XCSurroundWithActionSuffixKey     = @"XCSurroundWithActionSuffix";

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCSurroundWithAction ()

@property (nonatomic, copy) NSString *prefix;
@property (nonatomic, copy) NSString *suffix;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCSurroundWithAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithSpec:(NSDictionary *)spec
{
    if((self = [super init])) {
        self.title    = [NSString stringWithFormat:@"Surround text with %@", spec[XCSurroundWithActionTitleKey]];
        self.subtitle = [NSString stringWithFormat:@"Surrounds selection with %@", spec[XCSurroundWithActionSummaryKey]];
        self.prefix   = spec[XCSurroundWithActionPrefixKey];
        self.suffix   = spec[XCSurroundWithActionSuffixKey];
        self.enabled  = YES;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context
{
    return [self surroundTextSelectionInContext:context withPrefix:self.prefix andSuffix:self.suffix];
}

#pragma mark - Internal

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)surroundTextSelectionInContext:(id<XCIDEContext>)context withPrefix:(NSString *)prefix andSuffix:(NSString *)suffix
{
    NSArray *textSelectionRanges = [context retrieveTextSelectionRanges];
    XCReturnFalseUnless(TRCheckIsEmpty(textSelectionRanges) == NO);
    
    NSTextView *textView = context.sourceCodeTextView;
    NSString *text       = [textView.textStorage string];
    
    [textView.textStorage beginEditing];

    [textSelectionRanges enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSValue *value, NSUInteger idx, BOOL *stop) {
        NSRange range = value.rangeValue;

        NSMutableString *textSelectionSubstitution = [text substringWithRange:range].mutableCopy;
        if(TRCheckIsEmpty(textSelectionSubstitution) == YES) return;
        
        [textSelectionSubstitution insertString:prefix atIndex:0];
        [textSelectionSubstitution appendString:suffix];

        if([textView shouldChangeTextInRange:range replacementString:textSelectionSubstitution] == NO) {
            return;
        }

        [context.sourceCodeDocument.textStorage replaceCharactersInRange:range
                                                              withString:textSelectionSubstitution];
        [context.sourceCodeDocument.textStorage indentCharacterRange:range
                                                         undoManager:context.sourceCodeDocument.undoManager];
    }];
    
    [textView.textStorage endEditing];

    return YES;
}

@end
