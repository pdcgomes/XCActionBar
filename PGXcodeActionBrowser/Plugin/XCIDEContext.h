//
//  XCIDEContext.h
//  PGXcodeActionBrowser
//
//  Created by Pedro Gomes on 16/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@class IDEWorkspaceDocument, IDESourceCodeDocument, NSTextView;
@protocol XCIDEContext <NSObject>

@property (nonatomic,   weak) IDEWorkspaceDocument  *workspaceDocument;
@property (nonatomic,   weak) IDESourceCodeDocument *sourceCodeDocument;
@property (nonatomic, assign) NSTextView            *sourceCodeTextView; // does not support weak references

// Convenience API
- (NSRange)retrieveTextSelectionRange;
- (NSString *)retrieveTextSelection;

- (NSString *)retrievePasteboardTextContents;

- (BOOL)copyContentsToPasteboard:(id<NSPasteboardWriting>)contents;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCIDEContext : NSObject <XCIDEContext>

@end
