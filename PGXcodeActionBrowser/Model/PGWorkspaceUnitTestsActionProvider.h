//
//  PGUnitTestsActionProvider.h
//  PGXcodeActionBrowser
//
//  Created by Pedro Gomes on 10/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PGActionBrowserProvider.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@class IDEWorkspace;
@interface PGWorkspaceUnitTestsActionProvider : NSObject <PGActionProvider>

- (instancetype)initWithWorkspace:(IDEWorkspace *)workspace;

@end
