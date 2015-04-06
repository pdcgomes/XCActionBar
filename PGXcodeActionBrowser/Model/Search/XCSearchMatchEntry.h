//
//  XCSearchMatchEntry.h
//  XCActionBar
//
//  Created by Pedro Gomes on 06/04/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol XCActionInterface;
@protocol XCSearchMatchEntry <NSObject>

@property (nonatomic,         readonly) id<XCActionInterface> action;
@property (nonatomic, assign, readonly) NSRange rangeForMatch;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCSearchMatchEntry : NSObject <XCSearchMatchEntry>

- (instancetype)initWithAction:(id<XCActionInterface>)action rangeForMatch:(NSRange)rangeForMatch;

@end
