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

@property (nonatomic, readonly) id<XCActionInterface> action;
@property (nonatomic, readonly) NSArray *rangesForMatch;
@property (nonatomic, readonly) NSNumber *score;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCSearchMatchEntry : NSObject <XCSearchMatchEntry>

- (instancetype)initWithAction:(id<XCActionInterface>)action rangesForMatch:(NSArray *)rangesForMatch;
- (instancetype)initWithAction:(id<XCActionInterface>)action rangesForMatch:(NSArray *)rangesForMatch matchScore:(NSNumber *)score;

@end
