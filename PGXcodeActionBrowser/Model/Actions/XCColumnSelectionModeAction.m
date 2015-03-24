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
@interface XCColumnSelectionModeAction () <NSTextViewDelegate>

@property (nonatomic, strong) NSColor *insertionPointColor;
@property (nonatomic, assign) BOOL columnSelectionEnabled;
@property (nonatomic,   weak) id textViewDelegate;

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

typedef NS_ENUM(NSUInteger, XCTextSelectionType) {
    XCTextSelectionTypeColumn   = 1 << 0,
    XCTextSelectionTypeRow      = 1 << 1,
    XCTextSelectionTypeExpand   = 1 << 2,
    XCTextSelectionTypeContract = 1 << 3
};

//1/////////////////////////////////////////////////////////////////////////////
//2/////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)textView:(NSTextView *)textView willChangeSelectionFromCharacterRanges:(NSArray *)oldSelectedCharRanges toCharacterRanges:(NSArray *)newSelectedCharRanges
{
    NSLog(@"<oldRanges=%@>, <newRanges=%@>", oldSelectedCharRanges, newSelectedCharRanges);

    // FIXME: only supporting downstream selections for now, but shouldn't be to hard to support upstream
//    NSRange newSelectedCharRange = [newSelectedCharRanges.lastObject rangeValue];
////
//    NSString *fullText = textView.string;
//    NSString *textEnclosedBySelection = [fullText substringWithRange:newSelectedCharRange];
//    
//    __block NSUInteger lineCount = 0;
//    [textEnclosedBySelection enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
//        lineCount++;
//    }];
//    
//    NSLog(@"<lines=%zd>", lineCount);
    
    XCTextSelectionType selectionType = [self detectSelectionChangeTypeInTextView:textView fromCharacterRanges:oldSelectedCharRanges toCharacterRanges:newSelectedCharRanges];

    if(XCCheckOption(selectionType, XCTextSelectionTypeRow)) {
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
- (XCTextSelectionType)detectSelectionChangeTypeInTextView:(NSTextView *)textView fromCharacterRanges:(NSArray *)oldSelectedCharRanges toCharacterRanges:(NSArray *)toSelectedCharRanges
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
            XCTextSelectionTypeRow : 
            XCTextSelectionTypeColumn);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)processColumnSelectionForTextView:(NSTextView *)textView fromCharacterRanges:(NSArray *)oldSelectedCharRanges toCharacterRanges:(NSArray *)toSelectedCharRanges
{
    return toSelectedCharRanges;
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
    
    NSUInteger lineStart;
    NSUInteger lineEnd;
    
    [fullText getLineStart:&lineStart end:&lineEnd contentsEnd:NULL forRange:newSelectedCharRange];

    NSUInteger leadingOffset   = (referenceLineRange.location - lineRangeForSelection.location);
//    NSUInteger nextLineStart   = (lineStart + firstLineLength + 1) * (oldSelectedCharRanges.count);
    NSUInteger selectionWidth  = (referenceLineRange.length);

    NSRange dummyRangeForLastLine = (NSRange){
        .location = (newSelectedCharRange.location + newSelectedCharRange.length - 1),
        .length = 1
    };
    NSRange rangeForLastLine = [fullText lineRangeForRange:dummyRangeForLastLine];
    
    NSRange nextLineColSelection = NSMakeRange(rangeForLastLine.location + leadingOffset, selectionWidth);
    
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
