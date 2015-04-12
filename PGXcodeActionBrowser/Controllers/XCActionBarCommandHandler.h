//
//  XCActionBarCommandHandler.h
//  XCActionBar
//
//  Created by Pedro Gomes on 29/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol XCActionInterface;
@protocol XCActionBarStateController <NSObject>

- (void)enter;
- (void)exit;

- (BOOL)handleCancelCommand;
- (BOOL)handleCursorUpCommand;
- (BOOL)handleCursorDownCommand;
- (BOOL)handleCursorLeftCommand;
- (BOOL)handleCursorRightCommand;
- (BOOL)handleDoubleClickCommand;
- (BOOL)handleEnterCommand;
- (BOOL)handleTabCommand;
- (BOOL)handleTextInputCommand:(NSString *)text;

@optional
- (void)enterWithAction:(id<XCActionInterface>)action;

@end
