//
//  XCActionInterface.h
//  XCActionBar
//
//  Created by Pedro Gomes on 10/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol XCIDEContext;
@protocol XCActionInterface <NSObject>

@property (nonatomic,   copy) NSString *title;
@property (nonatomic,   copy) NSString *subtitle;
@property (nonatomic,   copy) NSString *hint;
@property (nonatomic,   copy) NSString *argumentHint;

@property (nonatomic,   copy) NSString *category;
@property (nonatomic,   copy) NSString *group;

@property (nonatomic, assign) BOOL    enabled;
@property (nonatomic, strong) NSImage *icon;

@property (nonatomic, strong) id representedObject;

- (BOOL)executeWithContext:(id<XCIDEContext>)context;

////////////////////////////////////////////////////////////////////////////////
// Arguments
////////////////////////////////////////////////////////////////////////////////
@optional

- (BOOL)acceptsArguments;

- (BOOL)requiresArguments;

- (BOOL)validateArgumentsWithContext:(id<XCIDEContext>)context arguments:(NSString *)arguments;

- (BOOL)executeWithContext:(id<XCIDEContext>)context arguments:(NSString *)arguments;

@end
