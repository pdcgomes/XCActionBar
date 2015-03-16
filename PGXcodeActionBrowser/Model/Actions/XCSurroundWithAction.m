//
//  XCSurroundWithAction.m
//  PGXcodeActionBrowser
//
//  Created by Pedro Gomes on 16/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XCIDEContext.h"
#import "XCIDEHelper.h"
#import "XCSurroundWithAction.h"

typedef BOOL (^XCSurroundWithFunction)(id<XCIDEContext> context);

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#define XCSurroundWithInfoPair(_title_, _summary_) @{@"title": _title_, @"summary": _summary_}
NSDictionary *XCSurroundWithActionInfo(XCSurroundWithType type)
{
    switch (type) {
        case XCSurroundWithTypeAutoreleasePool:     return XCSurroundWithInfoPair(@"Autorelease pool", @"@autoreleasepool { ... }");
        case XCSurroundWithTypeBrackets:            return XCSurroundWithInfoPair(@"Brackets", @"[ ... ]");
        case XCSurroundWithTypeCurlyBraces:         return XCSurroundWithInfoPair(@"Curly Braces", @"{ ... }");
        case XCSurroundWithTypeCustomText:          return XCSurroundWithInfoPair(@"Custom text", @"...");
        case XCSurroundWithTypeInlineBlock:         return XCSurroundWithInfoPair(@"Inline Block", @"...");
        case XCSurroundWithTypeNSNumber:            return XCSurroundWithInfoPair(@"NSNumber literal", @"@(...)");
        case XCSurroundWithTypeNSString:            return XCSurroundWithInfoPair(@"NSString literal", @"@\"\"");
        case XCSurroundWithTypeParenthesis:         return XCSurroundWithInfoPair(@"Parenthesis", @"( ... )");
        case XCSurroundWithTypePragmaAuditNonNull:  return XCSurroundWithInfoPair(@"Audio Non-null region", @"");
        case XCSurroundWithTypePragmaDiagnostic:    return XCSurroundWithInfoPair(@"Pragma diagnostic region", @"");
        case XCSurroundWithTypeQuotesDouble:        return XCSurroundWithInfoPair(@"Double quotes", @"\" ... \" ");
        case XCSurroundWithTypeQuotesSingle:        return XCSurroundWithInfoPair(@"Single qoutes", @"' ... '");
        case XCSurroundWithTypeSnippet:             return XCSurroundWithInfoPair(@"Apply code snippet", @"Applies the first token of the selected snippet");
        case XCSurroundWithTypeTryCatch:            return XCSurroundWithInfoPair(@"Try/Catch", @"@try{ ...} catch(NSException *exception) {}");
            
        default:
            NSCAssert(false, @"Unhandled XCSurroundWithType case");
            break;
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCSurroundWithAction ()

@property (nonatomic, assign) XCSurroundWithType type;
@property (nonatomic,   copy) XCSurroundWithFunction function;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *hint;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCSurroundWithAction

@synthesize title, subtitle, hint;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithType:(XCSurroundWithType)type
{
    if((self = [super init])) {
        NSDictionary *info = XCSurroundWithActionInfo(type);

        self.type     = type;
        self.title    = [NSString stringWithFormat:@"Surround with %@", info[@"title"]];
        self.subtitle = [NSString stringWithFormat:@"Surrounds selection with %@", info[@"summary"]];
        self.enabled = YES;

        RTVDeclareWeakSelf(weakSelf);
        
        XCSurroundWithFunction function = NULL;
        switch (type) {
            case XCSurroundWithTypeAutoreleasePool:     { function = ^(id<XCIDEContext> context) { return [weakSelf executeSurroundWithAutoreleasePool:context]; };     } break;
            case XCSurroundWithTypeBrackets:            { function = ^(id<XCIDEContext> context) { return [weakSelf executeSurroundWithBrackets:context]; };            } break;
            case XCSurroundWithTypeCurlyBraces:         { function = ^(id<XCIDEContext> context) { return [weakSelf executeSurroundWithCurlyBraces:context]; };         } break;
            case XCSurroundWithTypeCustomText:          { function = ^(id<XCIDEContext> context) { return [weakSelf executeSurroundWithCustomText:context]; };          } break;
            case XCSurroundWithTypeInlineBlock:         { function = ^(id<XCIDEContext> context) { return [weakSelf executeSurroundWithInlineBlock:context]; };         } break;
            case XCSurroundWithTypeNSNumber:            { function = ^(id<XCIDEContext> context) { return [weakSelf executeSurroundWithNSNumber:context]; };            } break;
            case XCSurroundWithTypeNSString:            { function = ^(id<XCIDEContext> context) { return [weakSelf executeSurroundWithNSString:context]; };            } break;
            case XCSurroundWithTypeParenthesis:         { function = ^(id<XCIDEContext> context) { return [weakSelf executeSurroundWithParenthesis:context]; };         } break;
            case XCSurroundWithTypePragmaAuditNonNull:  { function = ^(id<XCIDEContext> context) { return [weakSelf executeSurroundWithPragmaAuditNonNull:context]; };  } break;
            case XCSurroundWithTypePragmaDiagnostic:    { function = ^(id<XCIDEContext> context) { return [weakSelf executeSurroundWithPragmaDiagnostic:context]; };    } break;
            case XCSurroundWithTypeQuotesDouble:        { function = ^(id<XCIDEContext> context) { return [weakSelf executeSurroundWithQuotesDouble:context]; };        } break;
            case XCSurroundWithTypeQuotesSingle:        { function = ^(id<XCIDEContext> context) { return [weakSelf executeSurroundWithQuotesSingle:context]; };        } break;
            case XCSurroundWithTypeSnippet:             { function = ^(id<XCIDEContext> context) { return [weakSelf executeSurroundWithSnippet:context]; };             } break;
            case XCSurroundWithTypeTryCatch:            { function = ^(id<XCIDEContext> context) { return [weakSelf executeSurroundWithTryCatch:context]; };            } break;
                
            default:
                NSCAssert(false, @"Unhandled XCSurroundWithType case");
                break;
        }
        self.function = [function copy];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context
{
    return self.function(context);
}

#pragma mark - Handlers

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeSurroundWithAutoreleasePool:(id<XCIDEContext>)context
{
    NSString *prefix = @"@autoreleasepool {\n";
    NSString *suffix = @"\n}";
    
    return [self surroundTextSelectionInContext:context withPrefix:prefix andSuffix:suffix];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeSurroundWithBrackets:(id<XCIDEContext>)context
{
    NSString *prefix = @"[";
    NSString *suffix = @"]";
    
    return [self surroundTextSelectionInContext:context withPrefix:prefix andSuffix:suffix];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeSurroundWithCurlyBraces:(id<XCIDEContext>)context
{
    NSString *prefix = @"{\n";
    NSString *suffix = @"\n}";
    
    return [self surroundTextSelectionInContext:context withPrefix:prefix andSuffix:suffix];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeSurroundWithCustomText:(id<XCIDEContext>)context
{
    return NO;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeSurroundWithInlineBlock:(id<XCIDEContext>)context
{
    NSString *prefix = @"<#returnType#>(^<#blockName#>)(<#parameterTypes#>) = ^(<#parameters#>) {\n";
    NSString *suffix = @"};";
    
    return [self surroundTextSelectionInContext:context withPrefix:prefix andSuffix:suffix];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeSurroundWithNSNumber:(id<XCIDEContext>)context
{
    NSString *prefix = @"@(";
    NSString *suffix = @")";

    return [self surroundTextSelectionInContext:context withPrefix:prefix andSuffix:suffix];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeSurroundWithNSString:(id<XCIDEContext>)context
{
    NSString *prefix = @"@\"";
    NSString *suffix = @"\"";
    
    return [self surroundTextSelectionInContext:context withPrefix:prefix andSuffix:suffix];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeSurroundWithParenthesis:(id<XCIDEContext>)context
{
    NSString *prefix = @"(";
    NSString *suffix = @")";
    
    return [self surroundTextSelectionInContext:context withPrefix:prefix andSuffix:suffix];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeSurroundWithPragmaAuditNonNull:(id<XCIDEContext>)context
{
    NSString *prefix = @"NS_ASSUME_NONNULL_BEGIN\n";
    NSString *suffix = @"\nNS_ASSUME_NONNULL_END";

    return [self surroundTextSelectionInContext:context withPrefix:prefix andSuffix:suffix];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeSurroundWithPragmaDiagnostic:(id<XCIDEContext>)context
{
    NSString *prefix = (@"#pragma clang diagnostic push\n"
                        @"#pragma clang diagnostic ignored \"-Warc-performSelector-leaks\"\n");
    NSString *suffix = @"\n#pragma clang diagnostic pop";
    
    return [self surroundTextSelectionInContext:context withPrefix:prefix andSuffix:suffix];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeSurroundWithQuotesDouble:(id<XCIDEContext>)context
{
    NSString *prefix = @"\"";
    NSString *suffix = prefix;
    
    return [self surroundTextSelectionInContext:context withPrefix:prefix andSuffix:suffix];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeSurroundWithQuotesSingle:(id<XCIDEContext>)context
{
    NSString *prefix = @"'";
    NSString *suffix = prefix;
    
    return [self surroundTextSelectionInContext:context withPrefix:prefix andSuffix:suffix];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeSurroundWithSnippet:(id<XCIDEContext>)context
{
    return NO;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeSurroundWithTryCatch:(id<XCIDEContext>)context
{
    NSString *prefix = (@"@try {\n");
    NSString *suffix = (@"}\n"
                        @"@catch(NSException *exception) {\n"
                        @"\n}");
    
    return [self surroundTextSelectionInContext:context withPrefix:prefix andSuffix:suffix];
}

#pragma mark - Helpers

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSString *)retrieveTextSelectionInContext:(id<XCIDEContext>)context
{
    NSArray *selectedTextRanges = [context.sourceCodeTextView selectedRanges];
    if(TRCheckIsEmpty(selectedTextRanges) == YES) return nil;
    
    NSRange rangeForSelectedText = [selectedTextRanges.firstObject rangeValue];
    if(rangeForSelectedText.location == NSNotFound) return nil;

    return [context.sourceCodeTextView.textStorage.string substringWithRange:rangeForSelectedText];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)replaceTextSelectionInContext:(id<XCIDEContext>)context withText:(NSString *)replacementText
{
    NSRange rangeForSelectedText = [context retrieveTextSelectionRange];
    if(rangeForSelectedText.location == NSNotFound) return NO;
    
    NSTextView *textView = context.sourceCodeTextView;
    if([textView shouldChangeTextInRange:rangeForSelectedText replacementString:replacementText] == NO) {
        return NO;
    }

    NSRange rangeForSurroundedText = NSMakeRange(rangeForSelectedText.location, replacementText.length);

    [textView.textStorage beginEditing];
    
    [context.sourceCodeDocument.textStorage replaceCharactersInRange:rangeForSelectedText
                                                          withString:replacementText];
    [context.sourceCodeDocument.textStorage indentCharacterRange:rangeForSurroundedText
                                                     undoManager:context.sourceCodeDocument.undoManager];
    
    [textView.textStorage endEditing];

    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)surroundTextSelectionInContext:(id<XCIDEContext>)context withPrefix:(NSString *)prefix andSuffix:(NSString *)suffix
{
    NSMutableString *selection = [context retrieveTextSelection].mutableCopy;
    TR_RETURN_FALSE_UNLESS(TRCheckIsEmpty(selection) == NO);

    [selection insertString:prefix atIndex:0];
    [selection appendString:suffix];

    BOOL success = [self replaceTextSelectionInContext:context withText:selection];
    return success;
}

@end
