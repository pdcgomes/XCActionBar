//
//  PGBlockAction.h
//  XCActionBar
//
//  Created by Pedro Gomes on 10/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "PGActionInterface.h"

@protocol XCIDEContext;
typedef void(^XCBlockActionHandler)(id<XCIDEContext> context); // context can be nil

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface PGBlockAction : NSObject <PGActionInterface>

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
