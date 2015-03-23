//
//  XCSurroundLineWithAction.m
//  XCXcodeActionBrowser
//
//  Created by Pedro Gomes on 18/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCSurroundWithAction.h"
#import "XCSurroundLineWithAction.h"

#import "XCIDEContext.h"
#import "XCIDEHelper.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCSurroundLineWithAction ()

@property (nonatomic, copy) NSString *prefix;
@property (nonatomic, copy) NSString *suffix;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCSurroundLineWithAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithSpec:(NSDictionary *)spec
{
    if((self = [super init])) {
        self.title    = [NSString stringWithFormat:@"Surround lines with %@", spec[XCSurroundWithActionTitleKey]];
        self.subtitle = [NSString stringWithFormat:@"Surrounds each line with %@", spec[XCSurroundWithActionSummaryKey]];
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
    return [self surroundLineSelectionInContext:context withPrefix:self.prefix andSuffix:self.suffix];
}

////////////////////////////////////////////////////////////////////////////////
// REVIEW: this is currently adding the prefix/suffix including existing leading/trailing whitespace
//         it's almost definitely not what we want, so we should probably trim each line and re-indent them when done
////////////////////////////////////////////////////////////////////////////////
- (BOOL)surroundLineSelectionInContext:(id<XCIDEContext>)context withPrefix:(NSString *)prefix andSuffix:(NSString *)suffix
{
    NSTextView *textView = context.sourceCodeTextView;
    
    NSRange rangeForSelectedText  = [context retrieveTextSelectionRange];
    NSRange lineRangeForSelection = [textView.string lineRangeForRange:rangeForSelectedText];
    
    NSMutableArray *lineComponents = [[textView.string substringWithRange:lineRangeForSelection] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]].mutableCopy;
    [lineComponents removeLastObject];
    
    NSMutableString *replacementString = [[NSMutableString alloc] init];
    
    for(NSString *line in lineComponents) {
        [replacementString appendString:prefix];
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
    
    [context.sourceCodeDocument.textStorage indentCharacterRange:rangeForSelectedText
                                                     undoManager:context.sourceCodeDocument.undoManager];
    
    [textView.textStorage endEditing];
    
    return YES;
}

@end
