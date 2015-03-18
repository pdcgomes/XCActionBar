//
//  PGUtils.h
//  XCActionBar
//
//  Created by Pedro Gomes on 11/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *PGBuildModifierKeyMaskString(NSUInteger mask);

FOUNDATION_EXPORT void PGMethodSwizzle(Class class, SEL selector, SEL exchangeWithSelector);

FOUNDATION_EXPORT NSString *XCHashObject(id object);
