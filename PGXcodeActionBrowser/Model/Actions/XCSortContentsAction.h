//
//  XCSortContentsAction.h
//  XCXcodeActionBrowser
//
//  Created by Pedro Gomes on 16/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCCustomAction.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCSortContentsAction : XCCustomAction

- (instancetype)initWithSortOrder:(NSComparisonResult)sortOrder;

@end
