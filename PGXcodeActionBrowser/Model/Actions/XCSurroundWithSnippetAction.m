//
//  XCSurroundWithSnippetAction.m
//  XCActionBar
//
//  Created by Pedro Gomes on 18/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCSurroundWithSnippetAction.h"

#import "IDECodeSnippet.h"
#import "XCIDEContext.h"

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
    TR_RETURN_FALSE_UNLESS(outPrefix != NULL);
    TR_RETURN_FALSE_UNLESS(outSuffix != NULL);

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

////////////////////////////////////////////////////////////////////////////////
// REVIEW: move to internal/private header
////////////////////////////////////////////////////////////////////////////////
@interface XCSurroundWithAction ()

- (BOOL)surroundTextSelectionInContext:(id<XCIDEContext>)context withPrefix:(NSString *)prefix andSuffix:(NSString *)suffix;

@end

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
    return XCCheckTextSnippetCompatibility(snippet.contents);
}

#pragma mark - Dealloc and Initialization

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (instancetype)actionWithSnippet:(IDECodeSnippet *)snippet
{
    if([[self class] checkSnippetCompatibility:snippet] == NO) {
        [NSException raise:NSInternalInconsistencyException
                    format:(@"The provided snippet isn't compatible with SurroundWith actions."
                            @"Please make sure you test it with - checkSnippetCompatibility: before attempting to create the action")];
    }

    NSString *prefix = nil;
    NSString *suffix = nil;
    
    if(XCParseSnippetAndExtractPrefixAndSuffix(snippet.contents, &prefix, &suffix) == NO) {
        assert(false); // never reached
    }
    
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

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCSurroundWithTextSnippetAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (BOOL)checkTextSnippetCompatibility:(NSString *)snippet
{
    return XCCheckTextSnippetCompatibility(snippet);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithSpec:(NSDictionary *)spec
{
    NSMutableDictionary *mergedSpec = spec.mutableCopy;
    mergedSpec[XCSurroundWithActionPrefixKey] = @"";
    mergedSpec[XCSurroundWithActionSuffixKey] = @"";
    
    if((self = [super initWithSpec:spec])) {
        self.title    = [NSString stringWithFormat:@"Surround text with pasteboard snippet %@", spec[XCSurroundWithActionTitleKey]];
        self.subtitle = @"Surrounds selection with pasteboard \"Prefix <# token #> suffix\"";
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context
{
    NSString *textContents = [context retrievePasteboardTextContents];
    
    if(XCCheckTextSnippetCompatibility(textContents) == NO) {
        return NO;
    }

    NSString *prefix = nil;
    NSString *suffix = nil;
    
    if(XCParseSnippetAndExtractPrefixAndSuffix(textContents, &prefix, &suffix) == NO) {
        return NO;
    }

    return [self surroundTextSelectionInContext:context withPrefix:prefix andSuffix:suffix];
}

@end
