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

@property (nonatomic,   copy) NSString *category;
@property (nonatomic,   copy) NSString *group;

@property (nonatomic, assign) BOOL    enabled;
@property (nonatomic, strong) NSImage *icon;

@property (nonatomic, strong) id representedObject;
@property (nonatomic, strong) NSArray *searchQueryMatchRanges; // REVIEW:  this elsewhere

- (BOOL)executeWithContext:(id<XCIDEContext>)context;
- (BOOL)executeWithContext:(id<XCIDEContext>)context arguments:(NSArray *)arguments;


////////////////////////////////////////////////////////////////////////////////
// Arguments
////////////////////////////////////////////////////////////////////////////////
- (BOOL)acceptsArguments;

- (NSUInteger)requiredArgumentCount;

@end
