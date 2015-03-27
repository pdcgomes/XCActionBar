//
//  XCTextSnippetHelper.m
//  XCActionBar
//
//  Created by Pedro Gomes on 23/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCTextSnippetHelper.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
NSString *const XCExpandingTokenPattern = @"\\<\\#\\w*[^#]+\\#\\>";
//                                           |                          |
const NSUInteger XCPrefixCaptureGroupIndex = 1; //                      |
const NSUInteger XCSuffixCaptureGroupIndex = 3; // <--------------------/

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
BOOL XCCheckTextSnippetCompatibility(NSString *snippet)
{
    NSError *error = nil;
    NSRegularExpression *expression = [[NSRegularExpression alloc] initWithPattern:XCExpandingTokenPattern options:0 error:&error];
    if(expression == nil) return NO;
    
    BOOL compatible = ([expression numberOfMatchesInString:snippet options:0 range:NSMakeRange(0, snippet.length)] > 0);
    return compatible;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
BOOL XCParseSnippetAndExtractPrefixAndSuffix(NSString *snippet, NSString **outPrefix, NSString **outSuffix)
{
    XCReturnFalseUnless(outPrefix != NULL);
    XCReturnFalseUnless(outSuffix != NULL);
    
    NSRegularExpression *expression = [[NSRegularExpression alloc] initWithPattern:XCExpandingTokenPattern options:0 error:nil];
    NSString *snippetContents = snippet;
    
    NSTextCheckingResult *result = [expression firstMatchInString:snippetContents options:0 range:NSMakeRange(0, snippetContents.length)];
    NSCAssert(result.range.location != NSNotFound, @"No matches found!");
    
    NSUInteger endOfMatchLocation = (result.range.location + result.range.length);
    NSString *prefix = (result.range.location > 0 ? [snippetContents substringToIndex:result.range.location] : @"");
    NSString *suffix = (endOfMatchLocation < snippetContents.length ? [snippetContents substringFromIndex:endOfMatchLocation] : @"");
    
    *outPrefix = prefix;
    *outSuffix = suffix;
    
    return YES;
}