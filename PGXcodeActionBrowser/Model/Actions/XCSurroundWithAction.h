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
FOUNDATION_EXTERN NSString *const XCSurroundWithActionIdentifierKey;
FOUNDATION_EXTERN NSString *const XCSurroundWithActionTitleKey;
FOUNDATION_EXTERN NSString *const XCSurroundWithActionSummaryKey;
FOUNDATION_EXTERN NSString *const XCSurroundWithActionPrefixKey;
FOUNDATION_EXTERN NSString *const XCSurroundWithActionSuffixKey;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCSurroundWithAction : XCCustomAction

- (instancetype)initWithSpec:(NSDictionary *)spec;

@end
