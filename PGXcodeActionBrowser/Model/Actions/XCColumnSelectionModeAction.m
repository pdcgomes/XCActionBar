//
//  XCColumnSelectionAction.m
//  XCActionBar
//
//  Created by Pedro Gomes on 24/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCColumnSelectionModeAction.h"

#import "XCInputValidation.h"
#import "XCIDEContext.h"
#import "XCIDEHelper.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
typedef NS_ENUM(NSUInteger, XCTextSelectionCursorMode) {
    XCTextSelectionCursorModeColumn = 0,
    XCTextSelectionCursorModeRow,
    XCTextSelectionCursorModeUndefined,
};

typedef NS_ENUM(NSUInteger, XCTextSelectionResizingMode) {
    XCTextSelectionResizingModeUndefined   = 0,
    
    XCTextSelectionResizingModeExpanding   = 1 << 0,
    XCTextSelectionResizingModeContracting = 1 << 1,
    
    XCTextSelectionResizingModeForwards  = 1 << 2,
    XCTextSelectionResizingModeBackwards = 1 << 3,
};

// REVIEW: move this elsewhere
typedef struct XCLineRange {
    NSInteger start;
    NSInteger end;
} XCLineRange;

XCLineRange XCGetLineRangeForText(NSString *text, NSRange scannedRange)
{
    NSUInteger lineStart;
    NSUInteger lineEnd;
    
    [text getLineStart:&lineStart end:&lineEnd contentsEnd:NULL forRange:scannedRange];
    
    return (XCLineRange){
        .start = lineStart,
        .end   = lineEnd};
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCColumnSelectionModeAction () <NSTextViewDelegate>

@property (nonatomic, strong) NSColor *insertionPointColor;
@property (nonatomic, assign) BOOL    columnSelectionEnabled;
@property (nonatomic,   weak) id      textViewDelegate;

//@property (nonatomic) NSMutableDictionary *selectionTypeByTextView;
// FIXME: need to support this per text view
@property (nonatomic, readwrite) XCTextSelectionCursorMode   cursorMode;
@property (nonatomic, readwrite) XCTextSelectionResizingMode columnResizingMode;
@property (nonatomic, readwrite) XCTextSelectionResizingMode rowResizingMode;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCColumnSelectionModeAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)init
{
    if((self = [super init])) {
        self.title    = NSLocalizedString(@"Column Selection Mode", @"");
        self.subtitle = NSLocalizedString(@"Toggles column selectio mode on/off", @"");
        self.enabled  = YES;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context
{
    NSTextView *textView = context.sourceCodeTextView;

    self.cursorMode             = XCTextSelectionCursorModeUndefined;
    self.columnResizingMode     = XCTextSelectionResizingModeUndefined;
    self.rowResizingMode        = XCTextSelectionResizingModeUndefined;
    
    self.columnSelectionEnabled = !self.columnSelectionEnabled;
    
    if(self.columnSelectionEnabled == NO) {
        textView.delegate  = self.textViewDelegate;
        textView.insertionPointColor = self.insertionPointColor;
        
        self.textViewDelegate    = nil;
        self.insertionPointColor = nil;
    }
    else {
        self.textViewDelegate    = context.sourceCodeEditor;
        self.insertionPointColor = textView.insertionPointColor;
        
        textView.delegate = self;
        textView.insertionPointColor = [NSColor redColor];
    }
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)respondsToSelector:(SEL)aSelector
{
//    NSLog(@"<selector=%@", NSStringFromSelector(aSelector));

    if(self.columnSelectionEnabled == NO) return NO;
    
    if(aSelector == @selector(textView:willChangeSelectionFromCharacterRanges:toCharacterRanges:)) {
        return YES;
    }
    if(aSelector == @selector(textView:willChangeSelectionFromCharacterRange:toCharacterRange:)) {
        return NO;
    }
    return [self.textViewDelegate respondsToSelector:aSelector];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return self.textViewDelegate;
}

//1/////////////////////////////////////////////////////////////////////////////
//2/////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)textView:(NSTextView *)textView willChangeSelectionFromCharacterRanges:(NSArray *)oldSelectedCharRanges toCharacterRanges:(NSArray *)newSelectedCharRanges
{
    NSLog(@"<oldRanges=%@>, <newRanges=%@>", oldSelectedCharRanges, newSelectedCharRanges);

    XCTextSelectionCursorMode cursorMode = [self detectSelectionChangeTypeInTextView:textView fromCharacterRanges:oldSelectedCharRanges toCharacterRanges:newSelectedCharRanges];

    if(self.cursorMode != cursorMode) {
        self.cursorMode = cursorMode;
    }
    self.cursorMode = cursorMode;
    
    if(self.cursorMode == XCTextSelectionCursorModeRow) {
        return [self processRowSelectionForTextView:textView
                                fromCharacterRanges:oldSelectedCharRanges
                                  toCharacterRanges:newSelectedCharRanges];
    }
    return [self processColumnSelectionForTextView:textView
                               fromCharacterRanges:oldSelectedCharRanges
                                 toCharacterRanges:newSelectedCharRanges];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (XCTextSelectionCursorMode)detectSelectionChangeTypeInTextView:(NSTextView *)textView fromCharacterRanges:(NSArray *)oldSelectedCharRanges toCharacterRanges:(NSArray *)toSelectedCharRanges
{
    NSRange newSelectedCharRange = [toSelectedCharRanges.lastObject rangeValue];
    NSString *fullText = textView.string;
    NSString *textEnclosedBySelection = [fullText substringWithRange:newSelectedCharRange];
    
    __block NSUInteger lineCount = 0;
    [textEnclosedBySelection enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        lineCount++;
    }];

    NSLog(@"<lines=%zd>", lineCount);
    
    return (lineCount > 1 ?
            XCTextSelectionCursorModeRow :
            XCTextSelectionCursorModeColumn);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)processColumnSelectionForTextView:(NSTextView *)textView fromCharacterRanges:(NSArray *)oldSelectedCharRanges toCharacterRanges:(NSArray *)toSelectedCharRanges
{
    NSRange firstRowRange  = [oldSelectedCharRanges.firstObject rangeValue];
    NSRange oldColumnRange = [oldSelectedCharRanges.lastObject rangeValue];
    NSRange newColumnRange = [toSelectedCharRanges.lastObject rangeValue];

    // deselected by just moving the cursor without pressing any modifier key
    BOOL deselected = (
                       (newColumnRange.length == 0) ||
                       (toSelectedCharRanges.count  == 1 &&
                       (newColumnRange.location == oldColumnRange.location + oldColumnRange.length))
                       );
    if(deselected == YES) {
        self.columnResizingMode = XCTextSelectionResizingModeUndefined;
        return toSelectedCharRanges;
    };

    NSString *fullText = textView.string;

    if(oldSelectedCharRanges.count == 1) {
        self.columnResizingMode = (newColumnRange.location == oldColumnRange.location ?
                             (XCTextSelectionResizingModeExpanding | XCTextSelectionResizingModeForwards) :
                             (XCTextSelectionResizingModeExpanding | XCTextSelectionResizingModeBackwards));
        
        if(self.columnResizingMode == (XCTextSelectionResizingModeExpanding | XCTextSelectionResizingModeForwards)) {
            XCLineRange lineRange = XCGetLineRangeForText(fullText, oldColumnRange);
            BOOL resize = (oldColumnRange.location + newColumnRange.length < lineRange.end);

            if(resize == NO) return oldSelectedCharRanges;
        }
        return toSelectedCharRanges;
    }

    NSInteger selectionLeadOffsetModifier = 0;
    NSInteger selectionWidthModifier      = 0;
    if(newColumnRange.location  == oldColumnRange.location &&
       newColumnRange.length    == oldColumnRange.length + 1) {
        
        if(self.columnResizingMode == XCTextSelectionResizingModeUndefined) {
            self.columnResizingMode = (XCTextSelectionResizingModeExpanding | XCTextSelectionResizingModeForwards);
        }
        if(XCCheckOption(self.columnResizingMode, (XCTextSelectionResizingModeExpanding | XCTextSelectionResizingModeForwards))) {
            selectionWidthModifier = 1;
        }
        else {
            if(oldColumnRange.length > 1) {
                selectionWidthModifier      = -1;
                selectionLeadOffsetModifier = -1;
                
                self.columnResizingMode = (XCTextSelectionResizingModeContracting | XCTextSelectionResizingModeForwards);
            }
            else {
                self.columnResizingMode = (XCTextSelectionResizingModeExpanding | XCTextSelectionResizingModeForwards);
                selectionWidthModifier = 1;
            }
        }
    }
    else if(newColumnRange.location == oldColumnRange.location &&
            newColumnRange.length   == oldColumnRange.length - 1) {
        if(self.columnResizingMode == XCTextSelectionResizingModeUndefined) {
            self.columnResizingMode = (oldColumnRange.length > 1 ?
                                 (XCTextSelectionResizingModeContracting | XCTextSelectionResizingModeBackwards) :
                                 (XCTextSelectionResizingModeExpanding   | XCTextSelectionResizingModeBackwards));
//            self.resizingMode = (XCTextSelectionResizingModeExpanding | XCTextSelectionResizingModeBackwards);
        }
        if(XCCheckOption(self.columnResizingMode, (XCTextSelectionResizingModeExpanding | XCTextSelectionResizingModeBackwards))) {
            selectionWidthModifier      = 1;
            selectionLeadOffsetModifier = 1;
        }
        else selectionWidthModifier = -1;
    }
    else if(newColumnRange.location == firstRowRange.location &&
            newColumnRange.length == 1 &&
            toSelectedCharRanges.count > 1) {
        selectionWidthModifier      = 1;
        selectionLeadOffsetModifier = oldColumnRange.length + 1;
    }
    else if(/* newColumnRange.location == firstRowRange.location && */
            newColumnRange.length == 1 &&
            toSelectedCharRanges.count >= 1) {
        //
        selectionWidthModifier      = 1;
        selectionLeadOffsetModifier = 1;
        
        self.columnResizingMode = (XCTextSelectionResizingModeExpanding | XCTextSelectionResizingModeBackwards);
    }
    else if(newColumnRange.location == oldColumnRange.location &&
            newColumnRange.length    < oldColumnRange.length) {
        selectionWidthModifier      = 1;
        selectionLeadOffsetModifier = 1;
    }
    else {
        assert(false); // not reached
    }

    BOOL resize = YES;

    NSMutableArray *resizedCharRanges = oldSelectedCharRanges.mutableCopy;
    for(int i = 0; i < resizedCharRanges.count; i++) {
        NSRange range = [resizedCharRanges[i] rangeValue];
        
        if(XCCheckOption(self.columnResizingMode, XCTextSelectionResizingModeExpanding)) {

            if(XCCheckOption(self.columnResizingMode, XCTextSelectionResizingModeBackwards)) {
                XCLineRange lineRange = XCGetLineRangeForText(fullText, newColumnRange);
                resize = (newColumnRange.location != lineRange.start);
            }
            else if(XCCheckOption(self.columnResizingMode, XCTextSelectionResizingModeForwards)) {
                XCLineRange lineRange = XCGetLineRangeForText(fullText, range);
                resize = (range.location + newColumnRange.length < lineRange.end);
            }
        }
        
        if(resize == YES) {
            range.location -= selectionLeadOffsetModifier;
            range.length   += selectionWidthModifier;
            resizedCharRanges[i] = [NSValue valueWithRange:range];
        }
        else break;
    }
    
    NSLog(@"<resizedRanges=%@>", resizedCharRanges);

    return (resize ?
            resizedCharRanges :
            oldSelectedCharRanges);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)processRowSelectionForTextView:(NSTextView *)textView fromCharacterRanges:(NSArray *)oldSelectedCharRanges toCharacterRanges:(NSArray *)toSelectedCharRanges
{
    NSString *fullText = textView.string;

    NSRange newSelectedCharRange = [toSelectedCharRanges.lastObject rangeValue];

    if(oldSelectedCharRanges.count > 1) {
        NSRange lastRange = [oldSelectedCharRanges.lastObject rangeValue];
        newSelectedCharRange.location = lastRange.location;
    }
    
    NSRange referenceLineRange    = [oldSelectedCharRanges.lastObject rangeValue];
    NSRange lineRangeForSelection = [fullText lineRangeForRange:referenceLineRange];
    
//    XCLineRange lineRange = XCGetLineRangeForText(fullText, newSelectedCharRange);
    
    NSUInteger selectionLeadOffsetModifier = (referenceLineRange.location - lineRangeForSelection.location);
    NSUInteger selectionWidthModifier      = (referenceLineRange.length);

    NSRange dummyRangeForLastLine = (NSRange){
        .location = (newSelectedCharRange.location + newSelectedCharRange.length - 1),
        .length   = 1
    };
    NSRange rangeForLastLine = [fullText lineRangeForRange:dummyRangeForLastLine];
    
    NSRange nextLineColSelection = NSMakeRange(rangeForLastLine.location + selectionLeadOffsetModifier, selectionWidthModifier);
    
    // FIXME: account for prior zero length selection
//    NSRange nextLineColSelection = NSMakeRange(nextLineStart + leadingOffset, firstLineSelection.length);
    
    NSMutableArray *columnSelectionRanges = oldSelectedCharRanges.mutableCopy;
    if(oldSelectedCharRanges.count == 1) {
        [columnSelectionRanges removeLastObject];
        [columnSelectionRanges addObject:[NSValue valueWithRange:referenceLineRange]];
    }
    [columnSelectionRanges addObject:[NSValue valueWithRange:nextLineColSelection]];
    
    return columnSelectionRanges;
    
}

@end
