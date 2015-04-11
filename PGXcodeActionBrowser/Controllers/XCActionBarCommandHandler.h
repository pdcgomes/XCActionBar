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
@protocol XCActionBarStateController <NSObject>

- (void)enter;
- (void)exit;


- (BOOL)handleCancelCommand;
- (BOOL)handleCursorUpCommand;
- (BOOL)handleCursorDownCommand;
- (BOOL)handleDoubleClickCommand;
- (BOOL)handleEnterCommand;
- (BOOL)handleTabCommand;
- (BOOL)handleTextInputCommand:(NSString *)text;

@end
