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
@protocol XCActionBarCommandHandler <NSObject>

- (BOOL)handleCursorUpCommand;
- (BOOL)handleCursorDownCommand;
- (BOOL)handleEnterCommand;
- (BOOL)handleTabCommand;
- (BOOL)handleCancelCommand;

@end
