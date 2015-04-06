//
//  XCExpandTextSnippetAction.m
//  XCActionBar
//
//  Created by Pedro Gomes on 04/04/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "IDECodeSnippet.h"

#import "XCInputValidation.h"
#import "XCExpandCodeSnippetAction.h"

#import "XCIDEContext.h"
#import "XCIDEHelper.h"

NSString *const XCExpansionMacroAuthor    = @"@author";
NSString *const XCExpansionMacroClipboard = @"@clipboard";
NSString *const XCExpansionMacroCursor    = @"@cursor";
NSString *const XCExpansionMacroDate      = @"@date";
NSString *const XCExpansionMacroTime      = @"@time";

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCExpandCodeSnippetAction ()

@property (nonatomic) IDECodeSnippet *representedObject;

@property (nonatomic) NSDateFormatter *dateFormatter;
@property (nonatomic) NSDateFormatter *timeFormatter;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCExpandCodeSnippetAction

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithCodeSnippet:(IDECodeSnippet *)codeSnippet
{
    if((self = [super init])) {
        self.title    = codeSnippet.title;
        self.subtitle = codeSnippet.summary;
        self.hint     = codeSnippet.completionPrefix;
        self.enabled  = YES;
        
        self.representedObject = codeSnippet;
        
        self.dateFormatter = [[NSDateFormatter alloc] init];
        self.timeFormatter = [[NSDateFormatter alloc] init];

        self.dateFormatter.dateFormat = @"yyyy-dd-MM";
        self.timeFormatter.dateFormat = @"hh:mm:ss";
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context
{
    NSArray *expansionMacros = @[XCExpansionMacroAuthor,
                                 XCExpansionMacroClipboard,
                                 XCExpansionMacroCursor,
                                 XCExpansionMacroDate,
                                 XCExpansionMacroTime];
    
    NSString *snippetContents = self.representedObject.contents;
    
    NSMutableArray *macrosToExpand = [NSMutableArray array];
    for(NSString *macro in expansionMacros) { // TODO: consider making this a bit more efficient
        if([snippetContents containsString:macro]) [macrosToExpand addObject:macro];
    }
    
    if(TRCheckIsEmpty(macrosToExpand) == YES) [context.sourceCodeTextView insertText:snippetContents];
    else {
        [self expandSnippetWithMacrosInContext:context snippetContents:snippetContents macros:macrosToExpand];
    }
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)expandSnippetWithMacrosInContext:(id<XCIDEContext>)context snippetContents:(NSString *)snippet macros:(NSArray *)macros
{
    NSMutableString *snippetWithExpansions = snippet.mutableCopy;
    
    NSMutableArray *textMacros = macros.mutableCopy;
    
    BOOL moveCursor = ([textMacros containsObject:XCExpansionMacroCursor]);
    if(moveCursor) [textMacros removeObject:XCExpansionMacroCursor];
    
    NSDictionary *expansionHandlers = @{
                                        XCExpansionMacroAuthor:     NSStringFromSelector(@selector(expandAuthorInContext:snippet:)),
                                        XCExpansionMacroClipboard:  NSStringFromSelector(@selector(expandClipboardInContext:snippet:)),
                                        XCExpansionMacroDate:       NSStringFromSelector(@selector(expandDateInContext:snippet:)),
                                        XCExpansionMacroTime:       NSStringFromSelector(@selector(expandTimeInContext:snippet:)),
                                        };
 
    for(NSString *macro in textMacros) {
        NSString *selectorName = expansionHandlers[macro];
        SEL selector = NSSelectorFromString(selectorName);
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:selector withObject:context withObject:snippetWithExpansions];
#pragma clang diagnostic pop
    }
    
    if(moveCursor)  [self expandCursorInContext:context snippet:snippetWithExpansions];
    else            [context.sourceCodeTextView insertText:snippetWithExpansions];
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)expandAuthorInContext:(id<XCIDEContext>)context snippet:(NSMutableString *)string
{
    NSString *expansion = NSUserName(); // TODO: make user configurable
    
    [string replaceOccurrencesOfString:XCExpansionMacroAuthor withString:expansion options:0 range:NSMakeRange(0, string.length)];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)expandClipboardInContext:(id<XCIDEContext>)context snippet:(NSMutableString *)string
{
    NSString *expansion = [context retrievePasteboardTextContents] ?: @"";
    
    [string replaceOccurrencesOfString:XCExpansionMacroClipboard withString:expansion options:0 range:NSMakeRange(0, string.length)];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)expandCursorInContext:(id<XCIDEContext>)context snippet:(NSMutableString *)snippet
{
    NSUInteger cursorLocationBeforeExpansion = [context retrieveTextSelectionRange].location;
    NSUInteger cursorLocationAfterExpansion  = cursorLocationBeforeExpansion + [snippet rangeOfString:XCExpansionMacroCursor].location;
    
    [snippet replaceOccurrencesOfString:XCExpansionMacroCursor withString:@"" options:0 range:NSMakeRange(0, snippet.length)];
    
    [context.sourceCodeTextView insertText:snippet];
    [context.sourceCodeTextView setSelectedRange:NSMakeRange(cursorLocationAfterExpansion, 0)];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)expandDateInContext:(id<XCIDEContext>)context snippet:(NSMutableString *)string
{
     // TODO: make date format configurable
    NSString *expansion = [self.dateFormatter stringFromDate:[NSDate date]];
    
    [string replaceOccurrencesOfString:XCExpansionMacroDate withString:expansion options:0 range:NSMakeRange(0, string.length)];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)expandTimeInContext:(id<XCIDEContext>)context snippet:(NSMutableString *)string
{
     // TODO: make time format configurable
    NSString *expansion = [self.timeFormatter stringFromDate:[NSDate date]];
    
    [string replaceOccurrencesOfString:XCExpansionMacroTime withString:expansion options:0 range:NSMakeRange(0, string.length)];
}

@end
