//
//  XCActionBarConfiguration.h
//  XCActionBar
//
//  Created by Pedro Gomes on 20/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol XCActionBarConfiguration <NSObject>

// Interim representation while refactoring
@property (nonatomic, readonly) NSDictionary *shortcuts;

@property (nonatomic, readonly) NSArray *supportedTerminalApplications;

////////////////////////////////////////////////////////////////////////////////
// User Alerts
////////////////////////////////////////////////////////////////////////////////
@property (nonatomic, assign, readonly) BOOL userAlertsEnabledGlobally;
@property (nonatomic, assign, readonly) BOOL userAlertsEnabledForActions;

+ (BOOL)validateConfiguration:(NSDictionary *)configuration error:(NSError **)error;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCActionBarConfiguration : NSObject <XCActionBarConfiguration>

@property (nonatomic) NSDictionary *shortcuts;

@property (nonatomic) NSArray *supportedTerminalApplications;

////////////////////////////////////////////////////////////////////////////////
// User Alerts
////////////////////////////////////////////////////////////////////////////////
@property (nonatomic, assign) BOOL userAlertsEnabledGlobally;
@property (nonatomic, assign) BOOL userAlertsEnabledForActions;

- (instancetype)initWithDictionary:(NSDictionary *)configuration;

@end
