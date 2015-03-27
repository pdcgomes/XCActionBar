//
//  XCTextSnippetHelper.h
//  XCActionBar
//
//  Created by Pedro Gomes on 23/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
FOUNDATION_EXPORT NSString *const XCExpandingTokenPattern;

FOUNDATION_EXPORT const NSUInteger XCPrefixCaptureGroupIndex;
FOUNDATION_EXPORT const NSUInteger XCSuffixCaptureGroupIndex;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
FOUNDATION_EXPORT BOOL XCCheckTextSnippetCompatibility(NSString *snippet);
FOUNDATION_EXPORT BOOL XCParseSnippetAndExtractPrefixAndSuffix(NSString *snippet, NSString **outPrefix, NSString **outSuffix);
