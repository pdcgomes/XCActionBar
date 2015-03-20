//
//  XCNSMenuActionProvider.h
//  XCActionBar
//
//  Created by Pedro Gomes on 10/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//
#import <AppKit/AppKit.h>

#import "XCActionProvider.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCNSMenuActionProvider : NSObject <XCActionProvider>

- (instancetype)initWithMenu:(NSMenu *)menu;

@end
