//
//  XCColumnSelectionAction.m
//  XCActionBar
//
//  Created by Pedro Gomes on 24/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCColumnSelectionModeAction.h"

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
- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return self.textViewDelegate;

}

#pragma mark - XCColumnSelectionModeAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//- (NSRange)textView:(NSTextView *)textView willChangeSelectionFromCharacterRange:(NSRange)oldSelectedCharRange toCharacterRange:(NSRange)newSelectedCharRange
//{
//    return newSelectedCharRange;
//}

@end
