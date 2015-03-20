//
//  XCCustomActionProvider.h
//  XCXcodeActionBrowser
//
//  Created by Pedro Gomes on 16/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCActionProvider.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol XCIDEContext;
@interface XCCustomActionProvider : NSObject <NSUserInterfaceValidations, XCActionProvider>

- (instancetype)initWithCategory:(NSString *)category
                           group:(NSString *)group
                         actions:(NSArray *)actions
                         context:(id<XCIDEContext>)context;

@end
