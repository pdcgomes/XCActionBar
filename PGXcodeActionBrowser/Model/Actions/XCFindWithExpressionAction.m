//
//  XCFindWithExpressionAction.m
//  XCActionBar
//
//  Created by Pedro Gomes on 11/04/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCActionPreset.h"
#import "XCFindWithExpressionAction.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCFindWithExpressionAction ()

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCFindWithExpressionAction

@synthesize presetSummary;

////////////////////////////////////////////////////////////////////////////////        
////////////////////////////////////////////////////////////////////////////////
- (instancetype)init
{
    if((self = [super init])) {
        self.title         = @"Find with expression";
        self.subtitle      = @"Finds text matching the defined expression";
        self.presetSummary = @"Select an expression";
        self.enabled  = YES;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context
{
    return NO;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSUInteger)numberOfPresets
{
    return 0;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)retrievePresets
{
    return
    @[
      [[XCActionPreset alloc] initWithTitle:@"Date"             summary:@"Find dates" parent:self handler:nil],
      [[XCActionPreset alloc] initWithTitle:@"Email Address"    summary:@"Find email addresses" parent:self handler:nil],
      [[XCActionPreset alloc] initWithTitle:@"IP Address"       summary:@"Find IP addresses" parent:self handler:nil],
      [[XCActionPreset alloc] initWithTitle:@"Time"             summary:@"Find times" parent:self handler:nil],
      [[XCActionPreset alloc] initWithTitle:@"Timestamps"       summary:@"Find date/time timestamps" parent:self handler:nil],
      [[XCActionPreset alloc] initWithTitle:@"URL"              summary:@"Find URL addresses" parent:self handler:nil],
      ];
}

@end
