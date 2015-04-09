//
//  XCActionPreset.h
//  XCActionBar
//
//  Created by Pedro Gomes on 09/04/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol XCIDEContext;
@protocol XCActionPreset <NSObject>

@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *summary;

- (BOOL)executeWithContext:(id<XCIDEContext>)context;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol XCActionInterface;
@interface XCActionPreset : NSObject <XCActionPreset>

@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *summary;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithTitle:(NSString *)title
                      summary:(NSString *)summary
                       parent:(id<XCActionInterface>)action
                      handler:(SEL)handler;

@end
