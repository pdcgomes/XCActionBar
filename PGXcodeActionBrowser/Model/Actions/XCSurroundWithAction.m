//
//  XCSurroundWithAction.m
//  PGXcodeActionBrowser
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
        self.title    = [NSString stringWithFormat:@"Surround with %@", spec[XCSurroundWithActionTitleKey]];
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

#pragma mark - Helpers

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)replaceTextSelectionInContext:(id<XCIDEContext>)context withText:(NSString *)replacementText
{
    NSRange rangeForSelectedText = [context retrieveTextSelectionRange];
    if(rangeForSelectedText.location == NSNotFound) return NO;
    
    NSTextView *textView = context.sourceCodeTextView;
    if([textView shouldChangeTextInRange:rangeForSelectedText replacementString:replacementText] == NO) {
        return NO;
    }

    NSRange rangeForSurroundedText = NSMakeRange(rangeForSelectedText.location, replacementText.length);

    [textView.textStorage beginEditing];
    
    [context.sourceCodeDocument.textStorage replaceCharactersInRange:rangeForSelectedText
                                                          withString:replacementText];
    [context.sourceCodeDocument.textStorage indentCharacterRange:rangeForSurroundedText
                                                     undoManager:context.sourceCodeDocument.undoManager];
    
    [textView.textStorage endEditing];

    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)surroundTextSelectionInContext:(id<XCIDEContext>)context withPrefix:(NSString *)prefix andSuffix:(NSString *)suffix
{
    NSMutableString *selection = [context retrieveTextSelection].mutableCopy;
    TR_RETURN_FALSE_UNLESS(TRCheckIsEmpty(selection) == NO);

    [selection insertString:prefix atIndex:0];
    [selection appendString:suffix];

    BOOL success = [self replaceTextSelectionInContext:context withText:selection];
    return success;
}

@end
