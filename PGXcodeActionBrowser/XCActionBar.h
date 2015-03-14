//
//  XCActionBar.h
//  XCActionBar
//
//  Created by Pedro Gomes on 10/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <AppKit/AppKit.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCActionBar: NSObject

+ (instancetype)sharedPlugin;

@property (nonatomic, strong, readonly) NSBundle *bundle;

@end