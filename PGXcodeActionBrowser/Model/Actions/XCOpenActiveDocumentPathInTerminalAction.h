//
//  XCOpenActiveDocumentPathInTerminalAction.h
//  XCActionBar
//
//  Created by Pedro Gomes on 20/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCCustomAction.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCOpenActiveDocumentPathInTerminalAction : XCCustomAction

- (instancetype)initWithPrioritizedTerminalApplicationList:(NSArray *)applicationList;

@end
