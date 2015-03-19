//
//  XCHotKeyListener.h
//  XCActionBar
//
//  Created by Pedro Gomes on 18/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
typedef void (^XCHotKeyListenerHandler)(void);

FOUNDATION_EXPORT NSString *const XCHotKeyListenerHotKeyMaskKey;
FOUNDATION_EXPORT NSString *const XCHotKeyListenerRepeatCountKey;
FOUNDATION_EXPORT NSString *const XCHotKeyListenerRepeatDelayKey;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCHotKeyListener : NSObject

+ (BOOL)validateConfiguration:(NSDictionary *)configuration error:(NSError **)error;

- (instancetype)initWithConfiguration:(NSDictionary *)configuration handler:(XCHotKeyListenerHandler)handler;
- (instancetype)initWithConfiguration:(NSDictionary *)configuration target:(id)target action:(SEL)action;

- (BOOL)startListening;
- (BOOL)stopListening;

@end
