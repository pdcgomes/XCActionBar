//
//  XCJoinLinesAction.m
//  XCActionBar
//
//  Created by Pedro Gomes on 05/04/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCJoinLinesAction.h"

#import "XCIDEContext.h"
#import "XCIDEHelper.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCJoinLinesAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)init
{
    if((self = [super init])) {
        self.title    = @"Joins the selection's lines into one line";
        self.subtitle = @"Default deliminter is space, can be optionally specified";
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
        
        NSArray *lineComponents = [textSelection componentsSeparatedByString:@"\n"];
        
        NSMutableArray *trimmedLines = [NSMutableArray array];
        for(NSString *line in lineComponents) {
            NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            [trimmedLines addObject:trimmedLine];
        }

        NSString *joinedSelection = [trimmedLines componentsJoinedByString:@" "];

        [context.sourceCodeDocument.textStorage replaceCharactersInRange:range
                                                              withString:joinedSelection
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
