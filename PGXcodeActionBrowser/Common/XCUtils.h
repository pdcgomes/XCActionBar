//
//  PGUtils.h
//  XCActionBar
//
//  Created by Pedro Gomes on 11/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *XCBuildModifierKeyMaskString(NSUInteger mask);

FOUNDATION_EXPORT void XCMethodSwizzle(Class class, SEL selector, SEL exchangeWithSelector);

FOUNDATION_EXPORT NSString *XCHashObject(id object);

FOUNDATION_EXPORT NSString *XCEscapedTerminalPOSIXPath(NSString *path);
