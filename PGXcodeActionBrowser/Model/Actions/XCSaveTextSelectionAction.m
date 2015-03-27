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

#define XCSavedSelectionTextColor() ([[NSColor orangeColor] colorWithAlphaComponent:0.3])

NSString *XCTextSelectionMarkerAttributeName = @"XCTextSelectionMarker";

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

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)undoAction:(NSDictionary *)info
{
    NSTextView *textView         = info[@"TextView"];
    NSString *documentIdentifier = info[@"DocumentIdentifier"];
    NSArray *oldSelectionRanges  = info[@"OldSelectionRanges"];
    NSArray *newSelectionRanges  = info[@"NewSelectionRanges"];
    
    NSTextStorage *textStorage = textView.textStorage;
    
    for(NSValue *newRangeValue in newSelectionRanges) {
        NSRange newRange = [newRangeValue rangeValue];
        [textStorage removeAttribute:NSBackgroundColorAttributeName range:newRange];
        [textStorage removeAttribute:XCTextSelectionMarkerAttributeName range:newRange];
    }
    for(NSValue *oldRangeValue in oldSelectionRanges) {
        NSRange oldRange = [oldRangeValue rangeValue];
        
        [textStorage addAttributes:@{NSBackgroundColorAttributeName: XCSavedSelectionTextColor(),
                                     XCTextSelectionMarkerAttributeName: @(YES)}
                             range:oldRange];
    }
    
    [self.textSelectionStorage saveSelection:oldSelectionRanges withIdentifier:documentIdentifier];
}

////////////////////////////////////////////////////////////////////////////////
// Checks if the saved ranges are still valid (the user may have edited the document
// in the meantime - if all attributes match up, we're good to go, otherwise
// we need to re-scan the document for the appropriate strings
////////////////////////////////////////////////////////////////////////////////
- (BOOL)validateSavedSelectionsInContext:(id<XCIDEContext>)context documentIdentifier:(NSString *)documentIdentifier
{
    BOOL savedSelectionStillValid = YES;
    
    NSAttributedString *textView = context.sourceCodeTextView.textStorage;
    NSArray *savedSelections     = [self.textSelectionStorage loadSelectionWithIdentifier:documentIdentifier];
    
    @try {
        for(NSValue *value in savedSelections) {
            NSRange savedRange  = value.rangeValue;
            NSRange actualRange = {0, 0};
            
            id attribute = [textView attribute:XCTextSelectionMarkerAttributeName
                                       atIndex:savedRange.location
                         longestEffectiveRange:&actualRange
                                       inRange:value.rangeValue];
            BOOL validExpectation = (attribute != nil && NSEqualRanges(savedRange, actualRange));
            
            if(validExpectation == NO) {
                savedSelectionStillValid = NO;
                break;
            }
        }
    }
    @catch (NSException *exception) {
        savedSelectionStillValid = NO;
    }
    return savedSelectionStillValid;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)recomputeAndSaveSelectionsInContext:(id<XCIDEContext>)context documentIdentifier:(NSString *)documentIdentifier
{
    NSAttributedString *fullText = context.sourceCodeTextView.textStorage;
    
    NSMutableArray *ranges = [NSMutableArray array];
    [fullText enumerateAttribute:XCTextSelectionMarkerAttributeName inRange:NSMakeRange(0, fullText.length) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(id value, NSRange range, BOOL *stop) {
        if([fullText attribute:XCTextSelectionMarkerAttributeName atIndex:range.location effectiveRange:NULL]) {
            [ranges addObject:[NSValue valueWithRange:range]];
        }
    }];
    
    return [self.textSelectionStorage saveSelection:ranges withIdentifier:documentIdentifier];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)validateAndLoadSavedSelectionsInContext:(id<XCIDEContext>)context documentIdentifier:(NSString *)documentIdentifier
{
    if([self validateSavedSelectionsInContext:context documentIdentifier:documentIdentifier] == NO) {
        [self recomputeAndSaveSelectionsInContext:context documentIdentifier:documentIdentifier];
    }
    return [self.textSelectionStorage loadSelectionWithIdentifier:documentIdentifier];
}

@end

#pragma mark -

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
- (BOOL)executeWithContext:(id<XCIDEContext>)context
{
    NSTextView *textView        = context.sourceCodeTextView;
    NSTextStorage *textStorage  = textView.textStorage;
    NSArray *selectedTextRanges = [context retrieveTextSelectionRanges];
    
    NSMutableArray *selectedTextBlocks = [NSMutableArray array];
    
    for(NSValue *selectedTextRangeValue in selectedTextRanges) {
        NSRange selectedTextRange = [selectedTextRangeValue rangeValue];
        
        [textStorage addAttributes:@{NSBackgroundColorAttributeName: XCSavedSelectionTextColor(),
                                     XCTextSelectionMarkerAttributeName: @(YES)}
                             range:selectedTextRange];
        
        NSString *selectedText = [textStorage.string substringWithRange:selectedTextRange];
        [selectedTextBlocks addObject:selectedText];
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    NSString *documentIdentifier = [[context.sourceCodeDocument fileURL] absoluteString];
    
    NSArray *savedSelections = [self validateAndLoadSavedSelectionsInContext:context documentIdentifier:documentIdentifier];
    NSMutableArray *updatedSavedSelections = savedSelections.mutableCopy;
    
    [updatedSavedSelections addObjectsFromArray:selectedTextRanges];
    [updatedSavedSelections sortUsingComparator:^NSComparisonResult(NSValue *r1, NSValue *r2) {
        if(r1.rangeValue.location < r2.rangeValue.location) return NSOrderedAscending;
        if(r1.rangeValue.location > r2.rangeValue.location) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    [self mergeOverlappingRanges:updatedSavedSelections];
    
    ////////////////////////////////////////////////////////////////////////////////
    // Undo support
    ////////////////////////////////////////////////////////////////////////////////
    NSUndoManager *undo = textView.undoManager;
    [undo registerUndoWithTarget:self selector:@selector(undoAction:) object:@{@"TextView": textView,
                                                                               @"DocumentIdentifier": documentIdentifier,
                                                                               @"OldSelectionRanges": savedSelections,
                                                                               @"NewSelectionRanges": updatedSavedSelections}];
    
    ////////////////////////////////////////////////////////////////////////////////
    // Save selection
    ////////////////////////////////////////////////////////////////////////////////
    [self.textSelectionStorage saveSelection:updatedSavedSelections.copy withIdentifier:documentIdentifier];
    
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

#pragma mark -

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
    NSTextView *textView = context.sourceCodeTextView;
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    NSString *documentIdentifier = [[context.sourceCodeDocument fileURL] absoluteString];
    
    NSArray *savedSelections = [self.textSelectionStorage loadSelectionWithIdentifier:documentIdentifier];
    if(TRCheckIsEmpty(savedSelections) == YES) return NO;

    savedSelections = [self validateAndLoadSavedSelectionsInContext:context documentIdentifier:documentIdentifier];
    
    [textView setSelectedRanges:savedSelections affinity:NSSelectionAffinityDownstream stillSelecting:YES];
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
// Checks if the saved ranges are still valid (the user may have edited the document
// in the meantime - if all attributes match up, we're good to go, otherwise
// we need to re-scan the document for the appropriate strings
////////////////////////////////////////////////////////////////////////////////
- (BOOL)validateSavedSelectionsInContext:(id<XCIDEContext>)context documentIdentifier:(NSString *)documentIdentifier
{
    BOOL savedSelectionStillValid = YES;
    
    NSAttributedString *textView = context.sourceCodeTextView.textStorage;
    NSArray *savedSelections     = [self.textSelectionStorage loadSelectionWithIdentifier:documentIdentifier];
    
    @try {
        for(NSValue *value in savedSelections) {
            NSRange savedRange  = value.rangeValue;
            NSRange actualRange = {0, 0};
            
            id attribute = [textView attribute:XCTextSelectionMarkerAttributeName
                                       atIndex:savedRange.location
                         longestEffectiveRange:&actualRange
                                       inRange:value.rangeValue];
            BOOL validExpectation = (attribute != nil && NSEqualRanges(savedRange, actualRange));
            
            if(validExpectation == NO) {
                savedSelectionStillValid = NO;
                break;
            }
        }
    }
    @catch (NSException *exception) {
        savedSelectionStillValid = NO;
    }
    return savedSelectionStillValid;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)recomputeAndSaveSelectionsInContext:(id<XCIDEContext>)context documentIdentifier:(NSString *)documentIdentifier
{
    NSAttributedString *fullText = context.sourceCodeTextView.textStorage;
    
    NSMutableArray *ranges = [NSMutableArray array];
    [fullText enumerateAttribute:XCTextSelectionMarkerAttributeName inRange:NSMakeRange(0, fullText.length) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(id value, NSRange range, BOOL *stop) {
        if([fullText attribute:XCTextSelectionMarkerAttributeName atIndex:range.location effectiveRange:NULL]) {
            [ranges addObject:[NSValue valueWithRange:range]];
        }
    }];
    
    return [self.textSelectionStorage saveSelection:ranges withIdentifier:documentIdentifier];
}

@end

#pragma mark -

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
    
    NSArray *savedSelections = [self validateAndLoadSavedSelectionsInContext:context documentIdentifier:documentIdentifier];
    
    for(NSValue *selectedTextRangeValue in savedSelections) {
        NSRange selectedTextRange = [selectedTextRangeValue rangeValue];
        
        [textStorage removeAttribute:NSBackgroundColorAttributeName range:selectedTextRange];
        [textStorage removeAttribute:XCTextSelectionMarkerAttributeName range:selectedTextRange];
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    // Undo support
    ////////////////////////////////////////////////////////////////////////////////
    NSUndoManager *undo = textView.undoManager;
    [undo registerUndoWithTarget:self selector:@selector(undoAction:) object:@{@"TextView": textView,
                                                                               @"DocumentIdentifier": documentIdentifier,
                                                                               @"OldSelectionRanges": savedSelections,
                                                                               @"NewSelectionRanges": @[]}];
    
    [self.textSelectionStorage deleteSelectionWithIdentifier:documentIdentifier];
    
    return YES;
}

@end
