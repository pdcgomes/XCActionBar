//
//  XCActionBarSearchStateInputHandler.h
//  XCActionBar
//
//  Created by Pedro Gomes on 29/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCActionBarCommandHandler.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol XCActionBarCommandProcessor;
@protocol XCActionBarDataSource;
@interface XCActionBarSearchStateController : NSObject <XCActionBarStateController>

- (instancetype)initWithCommandProcessor:(id<XCActionBarCommandProcessor>)processor
                        searchDataSource:(id<XCActionBarDataSource>)dataSource
                               tableView:(NSTableView *)tableView
                              inputField:(NSTextField *)inputField;

@end
