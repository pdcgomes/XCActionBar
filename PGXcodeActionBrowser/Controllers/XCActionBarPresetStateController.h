//
//  XCActionBarPresetStateController.h
//  XCActionBar
//
//  Created by Pedro Gomes on 10/04/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCActionBarCommandHandler.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol XCActionBarCommandProcessor;
@interface XCActionBarPresetStateController : NSObject <XCActionBarStateController>

- (instancetype)initWithCommandProcessor:(id<XCActionBarCommandProcessor>)processor
                               tableView:(NSTableView *)tableView
                              inputField:(NSTextField *)inputField;

@end
