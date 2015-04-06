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

@property (nonatomic, assign) BOOL respondToMenuChanges; // generates index notification updates when this particular item (or chil-items change)

- (instancetype)initWithMenu:(NSMenu *)menu;

@end
