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
    XCTextSelectionCursorModeInitial,
};

typedef NS_ENUM(NSUInteger, XCTextSelectionResizingMode) {
    XCTextSelectionResizingModeUndefined   = 0,
    
    XCTextSelectionResizingModeExpanding   = 1 << 0,
    XCTextSelectionResizingModeContracting = 1 << 1,
    
    XCTextSelectionResizingModeForwards  = 1 << 2,
    XCTextSelectionResizingModeBackwards = 1 << 3,
    
    // Column Selection Mode Aliases
    XCTextSelectionResizingModeExpandingForwards    = (XCTextSelectionResizingModeExpanding     | XCTextSelectionResizingModeForwards),
    XCTextSelectionResizingModeExpandingBackwards   = (XCTextSelectionResizingModeExpanding     | XCTextSelectionResizingModeBackwards),
    XCTextSelectionResizingModeContractingForwards  = (XCTextSelectionResizingModeContracting   | XCTextSelectionResizingModeForwards),
    XCTextSelectionResizingModeContractingBackwards = (XCTextSelectionResizingModeContracting   | XCTextSelectionResizingModeBackwards),
    
    // Row Selection Mode Aliases
    XCTextSelectionResizingModeDown = XCTextSelectionResizingModeForwards,
    XCTextSelectionResizingModeUp   = XCTextSelectionResizingModeBackwards,
    
    XCTextSelectionResizingModeExpandingUp     = (XCTextSelectionResizingModeExpanding      | XCTextSelectionResizingModeUp),
    XCTextSelectionResizingModeExpandingDown   = (XCTextSelectionResizingModeExpanding      | XCTextSelectionResizingModeDown),
    XCTextSelectionResizingModeContractingUp   = (XCTextSelectionResizingModeContracting    | XCTextSelectionResizingModeUp),
    XCTextSelectionResizingModeContractingDown = (XCTextSelectionResizingModeContracting    | XCTextSelectionResizingModeDown),
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
    
    [self resetSelectionCursorAndResizingModes];
    
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

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)textView:(NSTextView *)textView willChangeSelectionFromCharacterRanges:(NSArray *)oldSelectedCharRanges toCharacterRanges:(NSArray *)newSelectedCharRanges
{
    //    NSLog(@"<oldRanges=%@>, <newRanges=%@>", oldSelectedCharRanges, newSelectedCharRanges);
    
    XCTextSelectionCursorMode cursorMode = [self detectSelectionChangeTypeInTextView:textView fromCharacterRanges:oldSelectedCharRanges toCharacterRanges:newSelectedCharRanges];
    
//    if(self.cursorMode != cursorMode) {
//        self.cursorMode = cursorMode;
//    }
    self.cursorMode = cursorMode;
    
    if(self.cursorMode == XCTextSelectionCursorModeUndefined) {
        [self resetSelectionCursorAndResizingModes];
        return newSelectedCharRanges;
    }
    if(self.cursorMode == XCTextSelectionCursorModeInitial) {
        return [self processCursorMovementWithNoPreviousSelection:textView
                                              fromCharacterRanges:oldSelectedCharRanges
                                                toCharacterRanges:newSelectedCharRanges];
    }
    
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
    NSRange oldSelectedCharRange = [oldSelectedCharRanges.lastObject rangeValue];
    NSRange newSelectedCharRange = [toSelectedCharRanges.lastObject rangeValue];
    NSString *fullText = textView.string;
    NSString *textEnclosedBySelection = [fullText substringWithRange:newSelectedCharRange];
    
    BOOL deselected = (toSelectedCharRanges.count == 1 && newSelectedCharRange.length == 0);
    if(deselected) return XCTextSelectionCursorModeUndefined;

    // REVIEW: not ideal, as this is causing side effects, which would not be expected given this method if for 'detection'
    BOOL initialSelection = (oldSelectedCharRanges.count == 1 && toSelectedCharRanges.count == 1 &&
                             oldSelectedCharRange.length == 0 && newSelectedCharRange.length != 0);
    if(initialSelection == YES) {
        return XCTextSelectionCursorModeInitial;
    }
    
    __block NSUInteger lineCount = 0;
    [textEnclosedBySelection enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        lineCount++;
    }];
    
    //    NSLog(@"<lines=%zd>", lineCount);
    
    if(oldSelectedCharRanges.count > 1 && toSelectedCharRanges.count == 1) {
        return XCTextSelectionCursorModeRow;
    }
    return (lineCount > 1 ?
            XCTextSelectionCursorModeRow :
            XCTextSelectionCursorModeColumn);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)processCursorMovementWithNoPreviousSelection:(NSTextView *)textView fromCharacterRanges:(NSArray *)oldSelectedCharRanges toCharacterRanges:(NSArray *)toSelectedCharRanges
{
    NSRange oldSelectedCharRange = [oldSelectedCharRanges.lastObject rangeValue];
    NSRange newSelectedCharRange = [toSelectedCharRanges.lastObject rangeValue];

    self.cursorMode         = XCTextSelectionCursorModeColumn;
    self.columnResizingMode = (XCTextSelectionResizingModeExpandingForwards);
    self.rowResizingMode    = (newSelectedCharRange.location == oldSelectedCharRange.location ?
                               XCTextSelectionResizingModeExpandingDown :
                               XCTextSelectionResizingModeExpandingUp);
    
    NSRange range = NSMakeRange(oldSelectedCharRange.location, 1);
    return @[[NSValue valueWithRange:range]];
}

#pragma mark - Column Selection

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
                                   (XCTextSelectionResizingModeExpandingForwards) :
                                   (XCTextSelectionResizingModeExpandingBackwards));
        
        // Prevent warping at the end of the line
        if(self.columnResizingMode == (XCTextSelectionResizingModeExpandingForwards)) {
            XCLineRange lineRange = XCGetLineRangeForText(fullText, oldColumnRange);
            BOOL resize = (oldColumnRange.location + newColumnRange.length < lineRange.end);
            
            if(resize == NO) return oldSelectedCharRanges;
        }
        return toSelectedCharRanges;
    }
    
    if(NSEqualRanges([toSelectedCharRanges.firstObject rangeValue], firstRowRange) == NO) {
        newColumnRange = [toSelectedCharRanges.firstObject rangeValue];
        oldColumnRange = [oldSelectedCharRanges.firstObject rangeValue];
    }
    
    NSInteger selectionLeadOffsetModifier = 0;
    NSInteger selectionWidthModifier      = 0;
    if(newColumnRange.location  == oldColumnRange.location &&
       newColumnRange.length    == oldColumnRange.length + 1) {
        
        if(self.columnResizingMode == XCTextSelectionResizingModeUndefined) {
            self.columnResizingMode = (XCTextSelectionResizingModeExpandingForwards);
        }
        if(XCCheckOption(self.columnResizingMode, (XCTextSelectionResizingModeExpandingForwards))) {
            //            selectionWidthModifier = 1;
        }
        else {
            if(oldColumnRange.length > 1) {
                if(self.columnResizingMode == XCTextSelectionResizingModeContractingBackwards) {
                    self.columnResizingMode = XCTextSelectionResizingModeExpandingForwards;
                }
                else self.columnResizingMode = (XCTextSelectionResizingModeContractingForwards);
            }
            else {
                self.columnResizingMode = (XCTextSelectionResizingModeExpandingForwards);
            }
        }
    }
    else if(newColumnRange.location == oldColumnRange.location &&
            newColumnRange.length   == oldColumnRange.length - 1) {
        if(self.columnResizingMode == XCTextSelectionResizingModeUndefined) {
            self.columnResizingMode = (oldColumnRange.length > 1 ?
                                       (XCTextSelectionResizingModeContractingBackwards) :
                                       (XCTextSelectionResizingModeExpandingBackwards));
        }
        else if(self.columnResizingMode == XCTextSelectionResizingModeExpandingForwards) {
            self.columnResizingMode = (oldColumnRange.length > 1 ?
                                       XCTextSelectionResizingModeContractingBackwards :
                                       XCTextSelectionResizingModeExpandingBackwards);
        }
        else if(self.columnResizingMode == XCTextSelectionResizingModeContractingForwards) {
            self.columnResizingMode = XCTextSelectionResizingModeExpandingBackwards;
        }
    }
    else if(/* newColumnRange.location == firstRowRange.location && */
            newColumnRange.length == 1 &&
            toSelectedCharRanges.count >= 1) {
        if(self.columnResizingMode == XCTextSelectionResizingModeContractingForwards) {
            self.columnResizingMode = XCTextSelectionResizingModeExpandingForwards;
        }
        else self.columnResizingMode = (XCTextSelectionResizingModeExpandingBackwards);
    }
    else if(newColumnRange.location == oldColumnRange.location + 1) {
        if(self.columnResizingMode == XCTextSelectionResizingModeExpandingBackwards) {
            self.columnResizingMode = XCTextSelectionResizingModeContractingForwards;
        }
        else if(self.columnResizingMode == XCTextSelectionResizingModeContractingBackwards) {
            self.columnResizingMode = XCTextSelectionResizingModeExpandingForwards;
        }
    }
    else if(newColumnRange.location == oldColumnRange.location - 1) {
        if(self.columnResizingMode == XCTextSelectionResizingModeExpandingForwards) {
            self.columnResizingMode = XCTextSelectionResizingModeContractingBackwards;
        }
        else if(self.columnResizingMode == XCTextSelectionResizingModeContractingBackwards &&
                newColumnRange.length == 2 && oldColumnRange.length == 1) {
            self.columnResizingMode = XCTextSelectionResizingModeExpandingBackwards;
        }
        else if(self.columnResizingMode == XCTextSelectionResizingModeContractingForwards) {
            self.columnResizingMode = XCTextSelectionResizingModeExpandingBackwards;
        }
    }
    else if(oldSelectedCharRanges.count > 1 && toSelectedCharRanges.count == 1) {
        return oldSelectedCharRanges;
        //assert(false); // not reached
    }
    else {
        XCLog(@"--> ZAP");
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    switch(self.columnResizingMode) {
        case XCTextSelectionResizingModeExpandingForwards:
            selectionWidthModifier = 1;
            break;
            
        case XCTextSelectionResizingModeExpandingBackwards:
            selectionWidthModifier      = 1;
            selectionLeadOffsetModifier = 1;
            break;
            
        case XCTextSelectionResizingModeContractingForwards:
            selectionWidthModifier      = -1;
            selectionLeadOffsetModifier = -1;
            break;
            
        case XCTextSelectionResizingModeContractingBackwards:
            selectionWidthModifier = -1;
            break;
            
        default: assert(false); // not reached
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////
    // Apply resizing
    ////////////////////////////////////////////////////////////////////////////////
    BOOL resize = YES;
    
    NSRange rangeForLineWidthCapSizing;
    if(XCCheckOption(self.rowResizingMode, XCTextSelectionResizingModeDown)) {
        rangeForLineWidthCapSizing = newColumnRange;
    }
    else {
        rangeForLineWidthCapSizing = [toSelectedCharRanges.firstObject rangeValue];
    }
    
    NSMutableArray *resizedCharRanges = oldSelectedCharRanges.mutableCopy;
    for(int i = 0; i < resizedCharRanges.count; i++) {
        NSRange range = [resizedCharRanges[i] rangeValue];
        
        if(XCCheckOption(self.columnResizingMode, XCTextSelectionResizingModeExpanding)) {
            
            if(XCCheckOption(self.columnResizingMode, XCTextSelectionResizingModeBackwards)) {
                XCLineRange lineRange = XCGetLineRangeForText(fullText, rangeForLineWidthCapSizing);
                resize = (rangeForLineWidthCapSizing.location != lineRange.start);
            }
            else if(XCCheckOption(self.columnResizingMode, XCTextSelectionResizingModeForwards)) {
                XCLineRange lineRange = XCGetLineRangeForText(fullText, range);
                NSRange resizedRange  = (NSRange){
                    range.location - selectionLeadOffsetModifier,
                    range.length + selectionWidthModifier
                };
//                resize = (range.location + rangeForLineWidthCapSizing.length < lineRange.end);
                resize = (resizedRange.location + resizedRange.length < lineRange.end);
            }
        }
        
        if(resize == YES) {
            range.location -= selectionLeadOffsetModifier;
            range.length   += selectionWidthModifier;
            resizedCharRanges[i] = [NSValue valueWithRange:range];
        }
        // TODO: maybe temporarily highlight the offending line so the user understands why the selection stopped
        // or just stop extending this particular range and cap it to its max. size?
        else break;
    }
    
    //    NSLog(@"<resizedRanges=%@>", resizedCharRanges);
    
    return (resize ?
            resizedCharRanges :
            oldSelectedCharRanges);
}

#pragma mark - Row Selection

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)processRowSelectionForTextView:(NSTextView *)textView fromCharacterRanges:(NSArray *)oldSelectedCharRanges toCharacterRanges:(NSArray *)toSelectedCharRanges
{
    NSString *fullText = textView.string;
    
    NSRange newSelectedCharRange = [toSelectedCharRanges.lastObject rangeValue];
    
    NSRange referenceLineRange    = [oldSelectedCharRanges.lastObject rangeValue];
    NSRange lineRangeForSelection = [fullText lineRangeForRange:referenceLineRange];
    
    if(self.rowResizingMode == XCTextSelectionResizingModeUndefined) {
        self.rowResizingMode = XCTextSelectionResizingModeExpanding;
        self.rowResizingMode |= (newSelectedCharRange.location < referenceLineRange.location ?
                                 XCTextSelectionResizingModeUp :
                                 XCTextSelectionResizingModeDown);
    }
    
    referenceLineRange = [oldSelectedCharRanges.firstObject rangeValue];
    lineRangeForSelection = [fullText lineRangeForRange:referenceLineRange];
    
    // FIXME: need to ensure we're looking into the correct old/new object index (some cases may need the first, others the last)
    BOOL atCrossover = (oldSelectedCharRanges.count == 1 && toSelectedCharRanges.count == 1);
    
    if(self.rowResizingMode == (XCTextSelectionResizingModeExpandingDown)) {
        
        if(newSelectedCharRange.location < referenceLineRange.location) {
            self.rowResizingMode = (atCrossover ?
                                    XCTextSelectionResizingModeExpandingUp :
                                    XCTextSelectionResizingModeContractingUp);
        }
    }
    else if(self.rowResizingMode == (XCTextSelectionResizingModeExpandingUp)) {
        
        if(newSelectedCharRange.location > referenceLineRange.location) {
            self.rowResizingMode = (atCrossover ?
                                    XCTextSelectionResizingModeExpandingDown :
                                    XCTextSelectionResizingModeContractingDown);
        }
    }
    else if(self.rowResizingMode == (XCTextSelectionResizingModeContractingUp)) {
        // Crossover point
        if(atCrossover == YES && newSelectedCharRange.location < referenceLineRange.location) {
            self.rowResizingMode = (XCTextSelectionResizingModeExpandingUp);
        }
        else if(newSelectedCharRange.location >= referenceLineRange.location) {
            self.rowResizingMode = (XCTextSelectionResizingModeExpandingDown);
        }
    }
    else if(self.rowResizingMode == (XCTextSelectionResizingModeContractingDown)) {
        
        if(atCrossover == YES && newSelectedCharRange.location >= referenceLineRange.location) {
            self.rowResizingMode = (XCTextSelectionResizingModeExpandingDown);
        }
        else if(newSelectedCharRange.location < referenceLineRange.location) {
            self.rowResizingMode = (XCTextSelectionResizingModeExpandingUp);
        }
    }
    else {
        assert(false); // never reached
    }
    
    switch(self.rowResizingMode) {
        case (XCTextSelectionResizingModeExpandingUp):
            return [self expandRowSelectionByMovingUp:textView fromCharacterRanges:oldSelectedCharRanges toCharacterRanges:toSelectedCharRanges];
            
        case (XCTextSelectionResizingModeExpandingDown):
            return [self expandRowSelectionByMovingDown:textView fromCharacterRanges:oldSelectedCharRanges toCharacterRanges:toSelectedCharRanges];
            
        case (XCTextSelectionResizingModeContractingUp):
            return [self contractSelectionByMovingUp:textView fromCharacterRanges:oldSelectedCharRanges toCharacterRanges:toSelectedCharRanges];
            
        case (XCTextSelectionResizingModeContractingDown):
            return [self contractSelectionByMovingDown:textView fromCharacterRanges:oldSelectedCharRanges toCharacterRanges:toSelectedCharRanges];
            
        default: assert(false); // not reached
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)expandRowSelectionByMovingUp:(NSTextView *)textView fromCharacterRanges:(NSArray *)oldSelectedCharRanges toCharacterRanges:(NSArray *)toSelectedCharRanges
{
    NSString *fullText = textView.string;
    
    NSRange referenceLineRange    = [oldSelectedCharRanges.firstObject rangeValue];
    NSRange lineRangeForSelection = [fullText lineRangeForRange:referenceLineRange];
    
    NSUInteger selectionLeadOffsetModifier = (referenceLineRange.location - lineRangeForSelection.location);
    NSUInteger selectionWidthModifier      = (referenceLineRange.length);
    
    BOOL selectNextLine = NO;
    NSRange rangeForNextLine = lineRangeForSelection;
    
    do {
        NSRange dummyRangeForLastLine = (NSRange){
            .location = (rangeForNextLine.location - 1),
            .length   = 1
        };
        rangeForNextLine = [fullText lineRangeForRange:dummyRangeForLastLine];
        selectNextLine   = ((rangeForNextLine.location + rangeForNextLine.length) >= (rangeForNextLine.location + selectionLeadOffsetModifier + selectionWidthModifier));
        
    } while(selectNextLine == NO && rangeForNextLine.location > 0);
    
    if(selectNextLine == NO) return oldSelectedCharRanges;
    
    NSRange nextLineSelection = NSMakeRange(rangeForNextLine.location + selectionLeadOffsetModifier, selectionWidthModifier);
    
    NSMutableArray *columnSelectionRanges = oldSelectedCharRanges.mutableCopy;
    if(oldSelectedCharRanges.count == 1) {
        [columnSelectionRanges removeLastObject];
        [columnSelectionRanges addObject:[NSValue valueWithRange:referenceLineRange]];
    }
    [columnSelectionRanges insertObject:[NSValue valueWithRange:nextLineSelection] atIndex:0];
    
    return columnSelectionRanges;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)expandRowSelectionByMovingDown:(NSTextView *)textView fromCharacterRanges:(NSArray *)oldSelectedCharRanges toCharacterRanges:(NSArray *)toSelectedCharRanges
{
    NSString *fullText = textView.string;
    
    NSRange referenceLineRange    = [oldSelectedCharRanges.lastObject rangeValue];
    NSRange lineRangeForSelection = [fullText lineRangeForRange:referenceLineRange];
    
    NSUInteger selectionLeadOffsetModifier = (referenceLineRange.location - lineRangeForSelection.location);
    NSUInteger selectionWidthModifier      = (referenceLineRange.length);
    
    BOOL selectNextLine = NO;
    NSRange rangeForNextLine = lineRangeForSelection;
    
    do {
        NSRange dummyRangeForLastLine = (NSRange){
            .location = (rangeForNextLine.location + rangeForNextLine.length),
            .length   = 1
        };
        @try { // raised when hittin the last line
            rangeForNextLine = [fullText lineRangeForRange:dummyRangeForLastLine];
        }
        @catch(NSException *exception) {
            break;
        }
        selectNextLine   = ((rangeForNextLine.location + rangeForNextLine.length) >= (rangeForNextLine.location + selectionLeadOffsetModifier + selectionWidthModifier));
        
    } while(selectNextLine == NO);
    
    if(selectNextLine == NO) return oldSelectedCharRanges;
    
    NSRange nextLineSelection = NSMakeRange(rangeForNextLine.location + selectionLeadOffsetModifier, selectionWidthModifier);
    
    NSMutableArray *columnSelectionRanges = oldSelectedCharRanges.mutableCopy;
    if(oldSelectedCharRanges.count == 1) {
        [columnSelectionRanges removeLastObject];
        [columnSelectionRanges addObject:[NSValue valueWithRange:referenceLineRange]];
    }
    [columnSelectionRanges addObject:[NSValue valueWithRange:nextLineSelection]];
    
    [textView scrollRangeToVisible:nextLineSelection];
    
    return columnSelectionRanges;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)contractSelectionByMovingUp:(NSTextView *)textView fromCharacterRanges:(NSArray *)oldSelectedCharRanges toCharacterRanges:(NSArray *)toSelectedCharRanges
{
    NSMutableArray *resizedRanges = oldSelectedCharRanges.mutableCopy;
    [resizedRanges removeLastObject];
    
    return resizedRanges;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)contractSelectionByMovingDown:(NSTextView *)textView fromCharacterRanges:(NSArray *)oldSelectedCharRanges toCharacterRanges:(NSArray *)toSelectedCharRanges
{
    NSMutableArray *resizedRanges = oldSelectedCharRanges.mutableCopy;
    [resizedRanges removeObjectAtIndex:0];
    
    return resizedRanges;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)resetSelectionCursorAndResizingModes
{
    self.cursorMode             = XCTextSelectionCursorModeUndefined;
    self.columnResizingMode     = XCTextSelectionResizingModeUndefined;
    self.rowResizingMode        = XCTextSelectionResizingModeUndefined;
}

@end
