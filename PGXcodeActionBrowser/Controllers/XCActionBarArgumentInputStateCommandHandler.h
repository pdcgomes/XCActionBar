//
//  XCActionBarArgumentInputStateHandler.h
//  XCActionBar
//
//  Created by Pedro Gomes on 29/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCActionBarCommandHandler.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol XCActionBarCommandProcessor;
@interface XCActionBarArgumentInputStateCommandHandler : NSObject <XCActionBarCommandHandler>

- (instancetype)initWithCommandProcessor:(id<XCActionBarCommandProcessor>)processor;

@end
