//
//  XCIDEContext.h
//  XCXcodeActionBrowser
//
//  Created by Pedro Gomes on 16/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
// REVIEW: not sure about this yet
////////////////////////////////////////////////////////////////////////////////
FOUNDATION_EXPORT NSString *const XCActionInfoTitleKey;
FOUNDATION_EXPORT NSString *const XCActionInfoSubtitleKey;
FOUNDATION_EXPORT NSString *const XCActionInfoSummaryKey;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@class IDEEditorDocument, IDEWorkspaceDocument, IDESourceCodeDocument, NSTextView;
@protocol XCIDEContext <NSObject>

@property (nonatomic,   weak) IDEWorkspaceDocument  *workspaceDocument;
@property (nonatomic,   weak) IDESourceCodeDocument *sourceCodeDocument;
@property (nonatomic,   weak) IDEEditorDocument     *editorDocument;
@property (nonatomic, assign) NSTextView            *sourceCodeTextView; // does not support weak references

// Convenience API
- (NSRange)retrieveTextSelectionRange;
- (NSString *)retrieveTextSelection;

- (NSString *)retrievePasteboardTextContents;

- (BOOL)copyContentsToPasteboard:(id<NSPasteboardWriting>)contents;

// REVIEW: not sure about this here yet... (@pedrogomes 20.03.2015)
- (BOOL)sendActionExecutionConfirmationWithInfo:(NSDictionary *)info;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCIDEContext : NSObject <XCIDEContext>

@end
