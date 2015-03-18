//
//  XCSurroundWithSnippetAction.m
//  XCActionBar
//
//  Created by Pedro Gomes on 18/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCSurroundWithSnippetAction.h"

#import "IDECodeSnippet.h"

NSString *const XCExpandingTokenPattern = @"\\<\\#\\w*[^#]+\\#\\>";
//                                           |                          |
const NSUInteger XCPrefixCaptureGroupIndex = 1; //                      |
const NSUInteger XCSuffixCaptureGroupIndex = 3; // <--------------------/

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCSurroundWithSnippetAction ()

@property (nonatomic) NSRegularExpression *expression;
@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCSurroundWithSnippetAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (BOOL)checkSnippetCompatibility:(IDECodeSnippet *)snippet
{
    NSError *error = nil;
    NSRegularExpression *expression = [[NSRegularExpression alloc] initWithPattern:XCExpandingTokenPattern options:0 error:&error];
    if(expression == nil) return NO;

    BOOL compatible = ([expression numberOfMatchesInString:snippet.contents options:0 range:NSMakeRange(0, snippet.contents.length)] > 0);
    return compatible;
}

#pragma mark - Dealloc and Initialization

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (instancetype)actionWithSnippet:(IDECodeSnippet *)snippet
{
    if([[self class] checkSnippetCompatibility:snippet] == NO) {
        [NSException raise:NSInternalInconsistencyException
                    format:(@"The provided snippet isn't compatible with SurroundWith actions."
                            @"Please make sure you test it with - (BOOL)checkSnippetCompatibility: before attempting to create the action")];
    }

    NSRegularExpression *expression = [[NSRegularExpression alloc] initWithPattern:XCExpandingTokenPattern options:0 error:nil];
    NSString *snippetContents = snippet.contents;
    
    NSTextCheckingResult *result = [expression firstMatchInString:snippetContents options:0 range:NSMakeRange(0, snippetContents.length)];
    NSAssert(result.range.location != NSNotFound, @"No matches found!");

    NSUInteger endOfMatchLocation = (result.range.location + result.range.length);
    NSString *prefix = (result.range.location > 0 ? [snippetContents substringToIndex:result.range.location] : @"");
    NSString *suffix = (endOfMatchLocation < snippetContents.length ? [snippetContents substringFromIndex:endOfMatchLocation] : @"");
    
//    NSAssert(TRCheckIsEmpty(prefix) == NO && TRCheckIsEmpty(suffix) == NO, @"Prefix and/or suffix unexpectedly empty");
    
    return [[self alloc] initWithSpec:@{XCSurroundWithActionIdentifierKey:  [NSString stringWithFormat:@"SurroundWithSnippetAction[%@]", snippet.identifier],
                                        XCSurroundWithActionTitleKey:       TRSafeString(snippet.title),
                                        XCSurroundWithActionSummaryKey:     TRSafeString(snippet.summary),
                                        XCSurroundWithActionPrefixKey:      prefix,
                                        XCSurroundWithActionSuffixKey:      suffix}];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithSpec:(NSDictionary *)spec
{
    if((self = [super initWithSpec:spec])) {
        self.title    = [NSString stringWithFormat:@"Surround text with snippet %@", spec[XCSurroundWithActionTitleKey]];
        self.subtitle = spec[XCSurroundWithActionSummaryKey];
    }
    return self;
}

@end
