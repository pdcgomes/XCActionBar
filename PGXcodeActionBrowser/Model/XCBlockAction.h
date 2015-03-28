//
//  XCBlockAction.h
//  XCActionBar
//
//  Created by Pedro Gomes on 10/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCActionInterface.h"

@protocol XCIDEContext;
typedef void(^XCBlockActionHandler)(id<XCIDEContext> context); // context can be nil

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCBlockAction : NSObject <XCActionInterface>

@property (nonatomic,   copy) NSString *title;
@property (nonatomic,   copy) NSString *subtitle;
@property (nonatomic,   copy) NSString *hint;

@property (nonatomic,   copy) NSString *category;
@property (nonatomic,   copy) NSString *group;

@property (nonatomic, assign) BOOL    enabled;
@property (nonatomic, strong) NSImage *icon;

@property (nonatomic, strong) id representedObject;
@property (nonatomic, copy) NSArray *searchQueryMatchRanges; // REVIEW:  this elsewhere

- (instancetype)initWithTitle:(NSString *)title
                       action:(XCBlockActionHandler)action;

- (instancetype)initWithTitle:(NSString *)title
                     subtitle:(NSString *)subtitle
                       action:(XCBlockActionHandler)action;

- (instancetype)initWithTitle:(NSString *)title
                     subtitle:(NSString *)subtitle
                         hint:(NSString *)hint
                       action:(XCBlockActionHandler)action;

@end
