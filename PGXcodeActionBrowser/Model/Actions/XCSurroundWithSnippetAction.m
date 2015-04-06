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
#import "XCTextSnippetHelper.h"

////////////////////////////////////////////////////////////////////////////////
// REVIEW: move to internal/private header
////////////////////////////////////////////////////////////////////////////////
@interface XCSurroundWithAction ()

- (BOOL)surroundTextSelectionInContext:(id<XCIDEContext>)context withPrefix:(NSString *)prefix andSuffix:(NSString *)suffix;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCSurroundLineWithAction ()

- (BOOL)surroundLineSelectionInContext:(id<XCIDEContext>)context withPrefix:(NSString *)prefix andSuffix:(NSString *)suffix;
- (BOOL)surroundLineSelectionInContext:(id<XCIDEContext>)context withPrefix:(NSString *)prefix andSuffix:(NSString *)suffix trimLines:(BOOL)trimLines;

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
        self.title    = spec[XCSurroundWithActionTitleKey];
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

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCSurroundLineWithTextSnippetAction

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
        self.title    = spec[XCSurroundWithActionTitleKey];
        self.subtitle = @"Surrounds lines with pasteboard \"Prefix <# token #> suffix\"";
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
    
    return [self surroundLineSelectionInContext:context withPrefix:prefix andSuffix:suffix trimLines:YES];
}

@end
