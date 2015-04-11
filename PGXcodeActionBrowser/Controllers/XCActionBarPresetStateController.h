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
@interface XCActionBarPresetCommandHandler : NSObject <XCActionBarStateController>

- (instancetype)initWithCommandProcessor:(id<XCActionBarCommandProcessor>)processor;

@end
