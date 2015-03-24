//
//  XCSaveSelectionAction.m
//  XCActionBar
//
//  Created by Pedro Gomes on 23/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCSaveTextSelectionAction.h"
#import "XCTextSelectionStorage.h"

#import "XCIDEContext.h"
#import "XCIDEHelper.h"
#import "XCInputValidation.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCTextSelectionAction ()

@property (nonatomic) id<XCTextSelectionStorage> textSelectionStorage;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCTextSelectionAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithTextSelectionStorage:(id<XCTextSelectionStorage>)textSelectionStorage
{
    if((self = [super init])) {
        self.textSelectionStorage = textSelectionStorage;
        self.enabled = YES;
    }
    return self;
}

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCSaveTextSelectionAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithTextSelectionStorage:(id<XCTextSelectionStorage>)textSelectionStorage
{
    if((self = [super initWithTextSelectionStorage:textSelectionStorage])) {
        self.title           = NSLocalizedString(@"Save selection", @"");
        self.subtitle        = NSLocalizedString(@"Save non-contiguous blocks of selected text", @"");
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#define XCSavedSelectionTextColor() ([[NSColor orangeColor] colorWithAlphaComponent:0.3])
- (BOOL)executeWithContext:(id<XCIDEContext>)context
{
    NSTextView *textView        = context.sourceCodeTextView;
    NSTextStorage *textStorage  = textView.textStorage;
    NSArray *selectedTextRanges = [context retrieveTextSelectionRanges];

    NSMutableArray *selectedTextBlocks = [NSMutableArray array];
    
    for(NSValue *selectedTextRangeValue in selectedTextRanges) {
        NSRange selectedTextRange = [selectedTextRangeValue rangeValue];
        
        [textStorage addAttribute:NSBackgroundColorAttributeName
                            value:XCSavedSelectionTextColor()
                            range:selectedTextRange];

        NSString *selectedText = [textStorage.string substringWithRange:selectedTextRange];
        [selectedTextBlocks addObject:selectedText];
    }

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    NSString *documentIdentifier = [[context.sourceCodeDocument fileURL] absoluteString];

    NSMutableArray *savedSelections = [self.textSelectionStorage loadSelectionWithIdentifier:documentIdentifier].mutableCopy;
    
    [savedSelections addObjectsFromArray:selectedTextRanges];
    [savedSelections sortUsingComparator:^NSComparisonResult(NSValue *r1, NSValue *r2) {
        if(r1.rangeValue.location < r2.rangeValue.location) return NSOrderedAscending;
        if(r1.rangeValue.location > r2.rangeValue.location) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    [self mergeOverlappingRanges:savedSelections];
    
    [self.textSelectionStorage saveSelection:savedSelections.copy withIdentifier:documentIdentifier];

    [textView setSelectedRanges:savedSelections affinity:NSSelectionAffinityDownstream stillSelecting:YES];
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)mergeOverlappingRanges:(NSMutableArray *)ranges
{
    if(ranges.count <= 1) return;
    
    for(NSUInteger cursor = 1; cursor < ranges.count;) {
        NSRange r1 = [ranges[cursor - 1] rangeValue];
        NSRange r2 = [ranges[cursor    ] rangeValue];

        if(NSIntersectionRange(r1, r2).location == 0) cursor++;
        else {
            NSRange mergedRanges = NSUnionRange(r1, r2);
            [ranges replaceObjectAtIndex:(cursor - 1) withObject:[NSValue valueWithRange:mergedRanges]];
            [ranges removeObjectAtIndex:cursor];
        }
    }
}

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCLoadTextSelectionAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithTextSelectionStorage:(id<XCTextSelectionStorage>)textSelectionStorage
{
    if((self = [super initWithTextSelectionStorage:textSelectionStorage])) {
        self.title           = NSLocalizedString(@"Load selection", @"");
        self.subtitle        = NSLocalizedString(@"Loads saved selection (marked text)", @"");
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context
{
    NSTextView *textView        = context.sourceCodeTextView;
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    NSString *documentIdentifier = [[context.sourceCodeDocument fileURL] absoluteString];
    
    NSMutableArray *savedSelections = [self.textSelectionStorage loadSelectionWithIdentifier:documentIdentifier].mutableCopy;
    
    [textView setSelectedRanges:savedSelections affinity:NSSelectionAffinityDownstream stillSelecting:YES];
    
    return YES;
}

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCClearTextSelectionAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithTextSelectionStorage:(id<XCTextSelectionStorage>)textSelectionStorage
{
    if((self = [super initWithTextSelectionStorage:textSelectionStorage])) {
        self.title           = NSLocalizedString(@"Clear selection", @"");
        self.subtitle        = NSLocalizedString(@"Clear the saved selection (marked text)", @"");
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context
{
    NSTextView *textView        = context.sourceCodeTextView;
    NSTextStorage *textStorage  = textView.textStorage;
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    NSString *documentIdentifier = [[context.sourceCodeDocument fileURL] absoluteString];
    
    NSMutableArray *savedSelections = [self.textSelectionStorage loadSelectionWithIdentifier:documentIdentifier].mutableCopy;
    
    for(NSValue *selectedTextRangeValue in savedSelections) {
        NSRange selectedTextRange = [selectedTextRangeValue rangeValue];

        [textStorage removeAttribute:NSBackgroundColorAttributeName range:selectedTextRange];
    }

    [self.textSelectionStorage deleteSelectionWithIdentifier:documentIdentifier];
    
    return YES;
}

@end
