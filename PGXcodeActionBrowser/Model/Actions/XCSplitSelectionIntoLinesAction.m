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
        self.title        = NSLocalizedString(@"Splits the selection into lines", @"");
        self.subtitle     = NSLocalizedString(@"Default delimiter: \",\", can be optionally specified", @"");
        self.argumentHint = NSLocalizedString(@"Specify the desired delimiter", @"");
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
    return arguments.length > 0;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context
{
    return [self splitSelectionInContext:context delimiter:@","];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context arguments:(NSString *)arguments
{
    return [self splitSelectionInContext:context delimiter:arguments];
}

#pragma mark - Helpers

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)splitSelectionInContext:(id<XCIDEContext>)context delimiter:(NSString *)delimiter
{
    NSString *fullText             = [context.sourceCodeTextView string];
    NSArray  *rangesForSelection   = [context retrieveTextSelectionRanges];
    NSString *newLineWithDelimiter = [NSString stringWithFormat:@"%@\n", delimiter];
    
    [context.sourceCodeDocument.textStorage beginEditing];

    [rangesForSelection enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSValue *value, NSUInteger idx, BOOL *stop) {
        NSRange range = value.rangeValue;
        
        NSString *textSelection = [fullText substringWithRange:range];
        NSString *textSelectionSplitByDelimiter = [textSelection stringByReplacingOccurrencesOfString:delimiter withString:newLineWithDelimiter];
        
        [context.sourceCodeDocument.textStorage replaceCharactersInRange:range
                                                              withString:textSelectionSplitByDelimiter
                                                         withUndoManager:context.sourceCodeDocument.undoManager];
        
        [context.sourceCodeDocument.textStorage indentCharacterRange:NSMakeRange(range.location, textSelectionSplitByDelimiter.length)
                                                         undoManager:context.sourceCodeDocument.undoManager];
    }];
    
    [context.sourceCodeDocument.textStorage endEditing];
    
    return YES;
    
}

@end
