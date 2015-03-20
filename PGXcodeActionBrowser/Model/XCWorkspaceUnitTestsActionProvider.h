//
//  XCUnitTestsActionProvider.h
//  XCActionBar
//
//  Created by Pedro Gomes on 10/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XCActionProvider.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@class IDEWorkspace;
@interface XCWorkspaceUnitTestsActionProvider : NSObject <XCActionProvider>

- (instancetype)initWithWorkspace:(IDEWorkspace *)workspace;

@end
