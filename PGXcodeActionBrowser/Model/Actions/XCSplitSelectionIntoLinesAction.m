//
//  XCSplitSelectionIntoLinesAction.m
//  XCActionBar
//
//  Created by Pedro Gomes on 05/04/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCSplitSelectionIntoLinesAction.h"

#import "XCIDEContext.h"
#import "XCIDEHelper.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCSplitSelectionIntoLinesAction ()

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCSplitSelectionIntoLinesAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)init
{
    if((self = [super init])) {
        self.title    = @"Splits the selection into lines";
        self.subtitle = @"Default deliminter: \",\", can be optionally specified";
        self.enabled  = YES;
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
    return NO;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context
{
    NSString *fullText           = [context.sourceCodeTextView string];
    NSArray  *rangesForSelection = [context retrieveTextSelectionRanges];

    [context.sourceCodeDocument.textStorage beginEditing];

    [rangesForSelection enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSValue *value, NSUInteger idx, BOOL *stop) {
        NSRange range = value.rangeValue;
    
        NSString *textSelection = [fullText substringWithRange:range];
        NSString *textSelectionSplitByDelimiter = [textSelection stringByReplacingOccurrencesOfString:@"," withString:@",\n"];
        
        [context.sourceCodeDocument.textStorage replaceCharactersInRange:range
                                                              withString:textSelectionSplitByDelimiter
                                                         withUndoManager:context.sourceCodeDocument.undoManager];
        
        [context.sourceCodeDocument.textStorage indentCharacterRange:range
                                                         undoManager:context.sourceCodeDocument.undoManager];
    }];
    
    [context.sourceCodeDocument.textStorage endEditing];
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context arguments:(NSString *)arguments
{
    return NO;
}

@end
