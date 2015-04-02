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
    NSTextView    *textView    = context.sourceCodeTextView;
    NSTextStorage *textStorage = textView.textStorage;
    
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
    NSUndoManager *undo = textView.undoManager;
    [undo registerUndoWithTarget:self selector:@selector(undoAction:) object:@{@"TextView": textView,
                                                                               @"DocumentIdentifier": documentIdentifier,
                                                                               @"OldSelectionRanges": savedSelections,
                                                                               @"NewSelectionRanges": @[]}];
    [self.textSelectionStorage deleteSelectionWithIdentifier:documentIdentifier];

    ////////////////////////////////////////////////////////////////////////////////
    // Retrieve the sub-selections we want to move
    ////////////////////////////////////////////////////////////////////////////////
    [textView.textStorage beginEditing];

    for(NSValue *selectedTextRangeValue in savedSelections) {
        NSRange selectedTextRange = [selectedTextRangeValue rangeValue];

        [textSelections addObject:[fullText substringWithRange:selectedTextRange]];
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    // Insert them in reverse order
    ////////////////////////////////////////////////////////////////////////////////
    [textSelections enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSString *selection, NSUInteger idx, BOOL *stop) {
        [textView insertText:selection];
    }];

    ////////////////////////////////////////////////////////////////////////////////
    // Reset the original selection
    ////////////////////////////////////////////////////////////////////////////////
    savedSelections = [self validateAndLoadSavedSelectionsInContext:context documentIdentifier:documentIdentifier];

    [savedSelections enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSValue *selectedTextRangeValue, NSUInteger idx, BOOL *stop) {
        NSRange selectedTextRange = [selectedTextRangeValue rangeValue];
        
        [textStorage removeAttribute:NSBackgroundColorAttributeName     range:selectedTextRange];
        [textStorage removeAttribute:XCTextSelectionMarkerAttributeName range:selectedTextRange];
        
        [textView replaceCharactersInRange:selectedTextRange withString:@""];
    }];

    [textView.textStorage endEditing];

//    ////////////////////////////////////////////////////////////////////////////////
//    // Undo support
//    ////////////////////////////////////////////////////////////////////////////////
//    NSUndoManager *undo = textView.undoManager;
//    [undo registerUndoWithTarget:self selector:@selector(undoAction:) object:@{@"TextView": textView,
//                                                                               @"DocumentIdentifier": documentIdentifier,
//                                                                               @"OldSelectionRanges": savedSelections,
//                                                                               @"NewSelectionRanges": @[]}];
//    [self.textSelectionStorage deleteSelectionWithIdentifier:documentIdentifier];
    
    return YES;
}

@end
