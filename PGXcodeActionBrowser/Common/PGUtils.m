//
//  PGUtils.m
//  XCActionBar
//
//  Created by Pedro Gomes on 11/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <objc/runtime.h>

#import "PGUtils.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
NSString *PGBuildModifierKeyMaskString(NSUInteger mask)
{
    static dispatch_once_t onceToken;
    static NSDictionary *flagsToStrMap = nil;
    static NSArray *orderedKeys = nil;
    dispatch_once(&onceToken, ^{
        flagsToStrMap = @{@(NSAlternateKeyMask):  @"\u2325",
                          @(NSControlKeyMask):    @"\u2303",
                          @(NSShiftKeyMask):      @"\u21e7",
                          @(NSCommandKeyMask):    @"\u2318"};
        
        orderedKeys   = @[@(NSAlternateKeyMask),
                          @(NSControlKeyMask),
                          @(NSShiftKeyMask),
                          @(NSCommandKeyMask)];
    });
    
    NSMutableString *str = [[NSMutableString alloc] init];
    for(NSNumber *key in orderedKeys) {
        if(TRCheckOption(mask, key.integerValue) == YES) {
            [str appendString:flagsToStrMap[key]];
        }
    }
    return str.copy;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
void PGMethodSwizzle(Class class, SEL selector, SEL exchangeWithSelector)
{
    Method method             = nil;
    Method exchangeWithMethod = nil;
    
    method             = class_getInstanceMethod(class, selector);
    exchangeWithMethod = class_getInstanceMethod(class, exchangeWithSelector);
    
    if(method != nil && exchangeWithMethod != nil) {
        method_exchangeImplementations(method, exchangeWithMethod);
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
NSString *XCHashObject(id object)
{
    if(XCHashObject == nil) return nil;
    
    return [NSString stringWithFormat:@"%lx", (long)object];
}
