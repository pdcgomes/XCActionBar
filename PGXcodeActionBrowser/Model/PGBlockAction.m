//
//  PGBlockAction.m
//  PGXcodeActionBrowser
//
//  Created by Pedro Gomes on 10/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "PGBlockAction.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface PGBlockAction ()

@property (nonatomic,   copy) NSString *title;
@property (nonatomic,   copy) NSString *subtitle;
@property (nonatomic,   copy) NSString *hint;

@property (nonatomic,   copy) dispatch_block_t action;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation PGBlockAction

@synthesize enabled, icon;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithTitle:(NSString *)title
                       action:(dispatch_block_t)action
{
    NSParameterAssert(title);
    NSParameterAssert(action);
    
    if((self = [self initWithTitle:title subtitle:@"" action:action])) {
        
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithTitle:(NSString *)title
                     subtitle:(NSString *)subtitle
                       action:(dispatch_block_t)action
{
    if((self = [self initWithTitle:title subtitle:subtitle hint:@"" action:action])) {
        
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithTitle:(NSString *)title
                     subtitle:(NSString *)subtitle
                         hint:(NSString *)hint
                       action:(dispatch_block_t)action
{
    NSParameterAssert(title);
    NSParameterAssert(action);

    if((self = [super init])) {
        self.title    = title;
        self.subtitle = subtitle;
        self.hint     = hint;
        self.action   = action;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)execute
{
    return NO;
}

@end
