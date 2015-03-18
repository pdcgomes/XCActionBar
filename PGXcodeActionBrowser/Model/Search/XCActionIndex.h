//
//  PGActionIndex.h
//  XCActionBar
//
//  Created by Pedro Gomes on 11/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol XCActionProvider;
@protocol PGActionIndex <NSObject>

- (id<NSCopying>)registerProvider:(id<XCActionProvider>)provider;
- (void)deregisterProvider:(id<NSCopying>)providerToken;

- (void)updateWithCompletionHandler:(PGGeneralCompletionHandler)completionHandler;

- (NSArray *)lookup:(NSString *)str;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCActionIndex : NSObject <PGActionIndex>

@end
