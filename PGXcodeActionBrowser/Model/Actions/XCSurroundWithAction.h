//
//  XCSurroundWithAction.h
//  PGXcodeActionBrowser
//
//  Created by Pedro Gomes on 16/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCCustomAction.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
typedef NS_ENUM(NSUInteger, XCSurroundWithType) {
    XCSurroundWithTypeAutoreleasePool,
    XCSurroundWithTypeBrackets,
    XCSurroundWithTypeCurlyBraces,
    XCSurroundWithTypeQuotesSingle,
    XCSurroundWithTypeQuotesDouble,
    XCSurroundWithTypeNSNumber,
    XCSurroundWithTypeNSString,
    XCSurroundWithTypeParenthesis,
    XCSurroundWithTypePragmaDiagnostic,
    XCSurroundWithTypePragmaAuditNonNull,
    XCSurroundWithTypeSnippet, // Applies the selected snippet as the first token of the selected expression -- be careful with this
    
    XCSurroundWithTypeCustomText, // Not yet supported
};

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCSurroundWithAction : XCCustomAction

- (instancetype)initWithType:(XCSurroundWithType)type;

@end
