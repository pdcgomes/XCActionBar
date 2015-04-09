//
//  XCUtils.m
//  XCActionBar
//
//  Created by Pedro Gomes on 11/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <objc/runtime.h>

#import "XCUtils.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
NSString *XCBuildModifierKeyMaskString(NSUInteger mask)
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
        if(XCCheckOption(mask, key.integerValue) == YES) {
            [str appendString:flagsToStrMap[key]];
        }
    }
    return str.copy;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
void XCMethodSwizzle(Class class, SEL selector, SEL exchangeWithSelector)
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
    if(object == nil) return nil;
    
    return [NSString stringWithFormat:@"%lx", (long)object];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
NSString *XCEscapedTerminalPOSIXPath(NSString *path)
{
    NSMutableCharacterSet *escapeCharacterSet = [[NSCharacterSet alphanumericCharacterSet] invertedSet].mutableCopy;
    [escapeCharacterSet removeCharactersInString:@"/"];
    [escapeCharacterSet removeCharactersInString:@"."];
    
    NSMutableString *escapedPath = [path mutableCopy];
    
    NSRange rangeOfScan  = NSMakeRange(0, path.length);
    NSRange rangeOfMatch = [path rangeOfCharacterFromSet:escapeCharacterSet options:NSBackwardsSearch range:rangeOfScan];
    
    while(rangeOfMatch.location != NSNotFound) {
        [escapedPath insertString:@"\\" atIndex:rangeOfMatch.location];
        
        rangeOfScan  = NSMakeRange(0, rangeOfMatch.location);
        rangeOfMatch = [path rangeOfCharacterFromSet:escapeCharacterSet options:NSBackwardsSearch range:rangeOfScan];
    }
    return escapedPath.copy;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
void XCSendUserNotification(NSString *title, NSString *subtitle, NSString *text, NSDictionary *userInfo)
{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title           = title;
    notification.subtitle        = subtitle;
    notification.informativeText = text;
    notification.userInfo        = userInfo;
    
    NSUserNotificationCenter *notificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
    [notificationCenter scheduleNotification:notification];
}
