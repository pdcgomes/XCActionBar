//
//  XCSortSelectionAction.h
//  XCXcodeActionBrowser
//
//  Created by Pedro Gomes on 16/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCCustomAction.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCSortSelectionAction : XCCustomAction

- (instancetype)initWithSortOrder:(NSComparisonResult)sortOrder
                    caseSensitive:(BOOL)caseSensitive;

@end
