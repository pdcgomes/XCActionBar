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

- (void)enterWithInputControl:(NSTextField *)field;
- (void)exit;


- (BOOL)handleCancelCommand;
- (BOOL)handleCursorUpCommand;
- (BOOL)handleCursorDownCommand;
- (BOOL)handleEnterCommand;
- (BOOL)handleTabCommand;
- (BOOL)handleTextInputCommand:(NSString *)text;

@end
