//
//  PGActionInterface.h
//  XCActionBar
//
//  Created by Pedro Gomes on 10/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol PGActionInterface <NSObject>

@property (nonatomic, readonly,   copy) NSString *title;
@property (nonatomic, readonly,   copy) NSString *subtitle;
@property (nonatomic, readonly,   copy) NSString *hint;

@property (nonatomic, copy) NSString *category;
@property (nonatomic, copy) NSString *group;

@property (nonatomic, assign) BOOL    enabled;
@property (nonatomic, strong) NSImage *icon;

@property (nonatomic, strong) id representedObject;

- (BOOL)execute;

@end
