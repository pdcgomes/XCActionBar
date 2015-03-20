//
//  XCIDEContext.m
//  XCXcodeActionBrowser
//
//  Created by Pedro Gomes on 16/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCIDEContext.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCIDEContext

@synthesize editorDocument, workspaceDocument, sourceCodeDocument, sourceCodeTextView;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSRange)retrieveTextSelectionRange
{
    NSArray *selectedTextRanges = [self.sourceCodeTextView selectedRanges];
    if(TRCheckIsEmpty(selectedTextRanges) == YES) return (NSRange){NSNotFound, -1};
    
    NSRange rangeForSelectedText = [selectedTextRanges.firstObject rangeValue];

    return rangeForSelectedText;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSString *)retrieveTextSelection
{
    NSRange rangeForSelectedText = [self retrieveTextSelectionRange];
    if(rangeForSelectedText.location == NSNotFound) return nil;
    
    return [self.sourceCodeTextView.textStorage.string substringWithRange:rangeForSelectedText];    
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSString *)retrievePasteboardTextContents
{
    NSArray *items = [[NSPasteboard generalPasteboard] readObjectsForClasses:@[[NSString class], [NSAttributedString class]] options:nil];

    return items.firstObject;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)copyContentsToPasteboard:(id<NSPasteboardWriting>)contents
{
    if(contents == nil) return NO;

    [[NSPasteboard generalPasteboard] clearContents];
    return [[NSPasteboard generalPasteboard] writeObjects:@[contents]];
}

@end
