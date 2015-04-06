//
//  XCMoveSelectionHereAction.m
//  XCActionBar
//
//  Created by Pedro Gomes on 02/04/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCMoveSelectionHereAction.h"
#import "XCTextSelectionStorage.h"

#import "XCIDEContext.h"
#import "XCIDEHelper.h"
#import "XCInputValidation.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCMoveSelectionHereAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithTextSelectionStorage:(id<XCTextSelectionStorage>)textSelectionStorage
{
    if((self = [super initWithTextSelectionStorage:textSelectionStorage])) {
        self.title           = NSLocalizedString(@"Move selection here", @"");
        self.subtitle        = NSLocalizedString(@"Moves the save selection(s) to the current line", @"");
        self.enabled         = YES;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context
{
    NSTextView           *textView    = context.sourceCodeTextView;
    DVTSourceTextStorage *textStorage = context.sourceCodeDocument.textStorage;
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    NSString *documentIdentifier = [[context.sourceCodeDocument fileURL] absoluteString];
    
    NSArray *savedSelections = [self validateAndLoadSavedSelectionsInContext:context documentIdentifier:documentIdentifier];
    XCReturnFalseUnless(TRCheckIsEmpty(savedSelections) == NO);
    
    NSString       *fullText       = textView.string;
    NSMutableArray *textSelections = [NSMutableArray array];

    ////////////////////////////////////////////////////////////////////////////////
    // Undo support
    ////////////////////////////////////////////////////////////////////////////////
    NSUndoManager *undo = context.sourceCodeDocument.undoManager;
    [undo beginUndoGrouping];
    [textStorage beginEditing];

    [undo registerUndoWithTarget:self selector:@selector(undoAction:) object:@{@"TextView": textView,
                                                                               @"DocumentIdentifier": documentIdentifier,
                                                                               @"OldSelectionRanges": savedSelections,
                                                                               @"NewSelectionRanges": @[]}];

    ////////////////////////////////////////////////////////////////////////////////
    // Retrieve the sub-selections we want to move
    ////////////////////////////////////////////////////////////////////////////////
    for(NSValue *selectedTextRangeValue in savedSelections) {
        NSRange selectedTextRange = [selectedTextRangeValue rangeValue];

        [textSelections addObject:[fullText substringWithRange:selectedTextRange]];
    }

    NSRange insertionLocation = NSMakeRange([context retrieveTextSelectionRange].location, 0);

    ////////////////////////////////////////////////////////////////////////////////
    // Insert them in reverse order
    ////////////////////////////////////////////////////////////////////////////////
    [textSelections enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSString *selection, NSUInteger idx, BOOL *stop) {
        [textStorage replaceCharactersInRange:insertionLocation
                                   withString:selection
                              withUndoManager:undo];
    }];

    ////////////////////////////////////////////////////////////////////////////////
    // Reset the original selection
    ////////////////////////////////////////////////////////////////////////////////
    savedSelections = [self validateAndLoadSavedSelectionsInContext:context documentIdentifier:documentIdentifier];

    [savedSelections enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSValue *selectedTextRangeValue, NSUInteger idx, BOOL *stop) {
        NSRange selectedTextRange = [selectedTextRangeValue rangeValue];
        
        [textStorage removeAttribute:NSBackgroundColorAttributeName     range:selectedTextRange];
        [textStorage removeAttribute:XCTextSelectionMarkerAttributeName range:selectedTextRange];
        
        [textStorage replaceCharactersInRange:selectedTextRange
                                   withString:@""
                              withUndoManager:undo];
    }];
    
    ////////////////////////////////////////////////////////////////////////////////
    // Delete the selection
    ////////////////////////////////////////////////////////////////////////////////
    [self.textSelectionStorage deleteSelectionWithIdentifier:documentIdentifier];

    [textStorage endEditing];
    [undo endUndoGrouping];

    return YES;
}

@end
