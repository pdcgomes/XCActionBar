//
//  XCSaveSelectionAction.m
//  XCActionBar
//
//  Created by Pedro Gomes on 23/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCSaveSelectionAction.h"

#import "XCIDEContext.h"
#import "XCIDEHelper.h"
#import "XCInputValidation.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCSaveSelectionAction ()

@property (nonatomic) NSMutableArray *savedSelections;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCSaveSelectionAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)init
{
    if((self = [super init])) {
        self.title           = NSLocalizedString(@"Save selection", @"");
        self.subtitle        = NSLocalizedString(@"Save non-contiguous blocks of selected text", @"");
        self.enabled         = YES;
        self.savedSelections = [NSMutableArray array];
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

    [self.savedSelections addObjectsFromArray:selectedTextRanges];
    [self.savedSelections sortUsingComparator:^NSComparisonResult(NSValue *r1, NSValue *r2) {
        if(r1.rangeValue.location < r2.rangeValue.location) return NSOrderedAscending;
        if(r1.rangeValue.location > r2.rangeValue.location) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    [self mergeOverlappingRanges:self.savedSelections];

    [textView setSelectedRanges:self.savedSelections affinity:NSSelectionAffinityDownstream stillSelecting:YES];
    
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
